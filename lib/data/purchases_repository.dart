import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/product.dart';
import 'auth_repository.dart';

class PurchasesRepository extends ChangeNotifier {
  static final PurchasesRepository _instance = PurchasesRepository._internal();
  factory PurchasesRepository() => _instance;
  PurchasesRepository._internal();

  final _supabase = Supabase.instance.client;
  List<Product> _purchases = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    AuthRepository().addListener(_setupUserListener);
    _setupUserListener();

    _isInitialized = true;
  }

  void _setupUserListener() {
    final user = AuthRepository().currentUser;
    if (user == null) {
      _purchases = [];
      notifyListeners();
      return;
    }

    _supabase
        .from('purchases')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('timestamp', ascending: false)
        .listen((data) {
          _purchases = data.map((json) => Product.fromJson(json)).toList();
          notifyListeners();
        });
  }

  List<Product> get purchases => List.unmodifiable(_purchases);

  Future<void> addPurchase(Product product) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      // Check for duplicates
      final data = await _supabase
          .from('purchases')
          .select()
          .eq('user_id', user.id)
          .eq('id', product.id)
          .maybeSingle();

      if (data == null) {
        // Map to table structure
        final productJson = product.toJson();
        productJson['user_id'] = user.id;

        await _supabase.from('purchases').insert(productJson);
      }
    } catch (e) {
      debugPrint('Error adding purchase to Supabase: $e');
    }
  }

  Future<void> clearData() async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      await _supabase.from('purchases').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error clearing purchases: $e');
    }
  }
}
