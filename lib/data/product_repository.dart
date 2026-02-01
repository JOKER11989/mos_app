import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'notifications_repository.dart';
import 'bids_repository.dart';
import 'auth_repository.dart';
import 'purchases_repository.dart';
import '../models/notification.dart';
import '../models/bid.dart';

class ProductRepository extends ChangeNotifier {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();

  final _supabase = Supabase.instance.client;
  List<Product> _products = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚡ ProductRepository: Already initialized, skipping...');
      return;
    }

    debugPrint('⚡ ProductRepository: Starting Supabase initialization...');

    // Listen to real-time updates from Supabase
    _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .listen(
          (data) {
            debugPrint(
              '⚡ ProductRepository: ✅ Stream received with ${data.length} rows',
            );

            _products = data
                .map((json) {
                  try {
                    // Supabase returns a Map<String, dynamic> directly
                    // We might need to ensure image array is handled correctly if stored as List<dynamic>
                    return Product.fromJson(json);
                  } catch (e) {
                    debugPrint(
                      '❌ ProductRepository: Error parsing product: $e',
                    );
                    return null;
                  }
                })
                .whereType<Product>() // Remove nulls
                .toList();

            debugPrint(
              '✅ ProductRepository: Parsed ${_products.length} valid products.',
            );
            notifyListeners();
            checkEndedAuctions();
          },
          onError: (e) {
            debugPrint('❌ ProductRepository: Error listening to products: $e');
          },
        );

    _isInitialized = true;
    debugPrint('✅ ProductRepository: Initialization complete');

    // Fix for Race Condition: Also check auctions when Bids are loaded/updated
    BidsRepository().addListener(() {
      debugPrint('⚡ ProductRepository: Bids updated, re-checking auctions...');
      checkEndedAuctions();
    });
  }

  Future<void> refresh() async {
    // Manual fetch if needed
    final data = await _supabase.from('products').select();
    _products = (data as List)
        .map((json) {
          try {
            return Product.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing product in refresh: $e');
            return null;
          }
        })
        .whereType<Product>()
        .toList();
    notifyListeners();
  }

  List<Product> get products => List.unmodifiable(_products);

  List<Product> get activeProducts {
    final now = DateTime.now();
    return _products.where((p) {
      if (p.endTime == null) return true;
      return p.endTime!.isAfter(now);
    }).toList();
  }

  List<Product> get endedProducts {
    final now = DateTime.now();
    return _products.where((p) {
      if (p.endTime == null) return false;
      return p.endTime!.isBefore(now);
    }).toList();
  }

  // المنتجات العادية (ليست عروض تايتل)
  List<Product> get regularProducts {
    return activeProducts.where((p) => !p.isOffer).toList();
  }

  // عروض التايتل فقط
  List<Product> get offerProducts {
    return activeProducts.where((p) => p.isOffer).toList();
  }

  Future<void> addProduct(Product product) async {
    try {
      debugPrint('⚡ Adding product to Supabase: ${product.id}');

      // Supabase expects normal JSON maps.
      // simple_json conversion handles most types, but ensure Dates are ISO strings if needed.
      // Product.toJson() should already produce compatible Map.

      await _supabase.from('products').insert(product.toJson());

      debugPrint('✅ Product successfully added to Supabase: ${product.id}');
    } catch (e) {
      debugPrint('❌ Error adding product to Supabase: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    // Optimistic Update: Update local list immediately
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }

    try {
      await _supabase
          .from('products')
          .update(product.toJson())
          .eq('id', product.id);
    } catch (e) {
      debugPrint('Error updating product in Supabase: $e');
      // Revert optimization if needed, but stream usually handles correction
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting product from Supabase: $e');
    }
  }

  // فحص المزادات المنتهية لإرسال إشعارات
  void checkEndedAuctions() {
    final now = DateTime.now();
    final currentUser = AuthRepository().currentUser;

    if (currentUser == null) return;

    final bidsRepo = BidsRepository();
    final notifRepo = NotificationsRepository();

    for (final product in _products) {
      if (product.endTime != null && product.endTime!.isBefore(now)) {
        if (bidsRepo.hasBidOn(product.id)) {
          final latestBid = bidsRepo.getLatestBidForProduct(product.id);
          _checkAndNotify(product, latestBid, notifRepo);
        }
      }
    }
  }

  Future<void> _checkAndNotify(
    Product product,
    Bid? latestBid,
    NotificationsRepository notifRepo,
  ) async {
    final currentUser = AuthRepository().currentUser;
    if (currentUser == null) return;

    bool isWinner = false;

    if (latestBid != null) {
      isWinner = latestBid.userId == currentUser.id;
    }

    notifRepo.addNotification(
      title: isWinner ? "فزت بالمزايدة!" : "انتهى المزاد",
      message: isWinner
          ? "تهانينا! لقد فزت بمنتج ${product.name}."
          : "انتهى المزاد على ${product.name}. تفقد النتائج الآن!",
      type: isWinner ? NotificationType.won : NotificationType.auctionEnd,
      productId: product.id,
    );

    if (isWinner) {
      PurchasesRepository().addPurchase(product);
    }
  }
}
