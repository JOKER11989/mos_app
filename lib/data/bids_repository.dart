import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bid.dart';
import 'auth_repository.dart';

class BidsRepository extends ChangeNotifier {
  static final BidsRepository _instance = BidsRepository._internal();
  factory BidsRepository() => _instance;
  BidsRepository._internal();

  final _firestore = FirebaseFirestore.instance;

  // سجل كامل للمزايدات (يتم تحديثه لحظياً من فيربيس)
  List<Bid> _bidHistory = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen to ALL bids in real-time
    _firestore.collection('bids').snapshots().listen((snapshot) {
      _bidHistory = snapshot.docs
          .map((doc) => Bid.fromJson(doc.data()))
          .toList();
      notifyListeners();
    });

    _isInitialized = true;
  }

  // IDs المنتجات التي زايد عليها المستخدم الحالي
  List<String> get biddedProductIds {
    final currentUserId = AuthRepository().currentUser?.id;
    if (currentUserId == null) return [];

    return _bidHistory
        .where((bid) => bid.userId == currentUserId)
        .map((bid) => bid.productId)
        .toSet()
        .toList();
  }

  bool hasBidOn(String productId) {
    final currentUserId = AuthRepository().currentUser?.id;
    if (currentUserId == null) return false;
    return _bidHistory.any(
      (bid) => bid.productId == productId && bid.userId == currentUserId,
    );
  }

  // إضافة مزايدة جديدة إلى فيربيس
  Future<void> addBid({
    required String productId,
    required String userId,
    required String bidderName,
    required int amount,
  }) async {
    final bid = Bid(
      id: 'bid_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      userId: userId,
      bidderName: bidderName,
      amount: amount,
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.collection('bids').doc(bid.id).set(bid.toJson());
    } catch (e) {
      debugPrint('Error adding bid to Firestore: $e');
    }
  }

  // الحصول على جميع المزايدات لمنتج معين
  List<Bid> getBidsForProduct(String productId) {
    final productBids = _bidHistory
        .where((bid) => bid.productId == productId)
        .toList();
    productBids.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    ); // الأحدث أولاً
    return productBids;
  }

  // الحصول على آخر مزايدة لمنتج معين
  Bid? getLatestBidForProduct(String productId) {
    final bids = getBidsForProduct(productId);
    return bids.isNotEmpty ? bids.first : null;
  }

  // عدد المزايدات لمنتج معين
  int getBidCountForProduct(String productId) {
    return _bidHistory.where((bid) => bid.productId == productId).length;
  }

  // عدد المزايدين الفريدين لمنتج معين
  int getUniqueBiddersCountForProduct(String productId) {
    final userIds = _bidHistory
        .where((bid) => bid.productId == productId)
        .map((bid) => bid.userId)
        .toSet();
    return userIds.length;
  }

  // الحصول على جميع مزايدات مستخدم معين
  List<Bid> getUserBids(String userId) {
    final userBids = _bidHistory.where((bid) => bid.userId == userId).toList();
    userBids.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return userBids;
  }

  Future<void> clearData() async {
    // In Firebase context, clearData usually means local session cleanup if needed,
    // but the bids themselves are global.
    // If the user wants to delete their own bids, that would be a different method.
    _bidHistory.clear();
    notifyListeners();
  }
}
