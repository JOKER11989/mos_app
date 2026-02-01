import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'auth_repository.dart';

class PurchasesRepository extends ChangeNotifier {
  static final PurchasesRepository _instance = PurchasesRepository._internal();
  factory PurchasesRepository() => _instance;
  PurchasesRepository._internal();

  final _firestore = FirebaseFirestore.instance;
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

    // Real-time listener for this user's purchases
    _firestore
        .collection('users')
        .doc(user.id)
        .collection('purchases')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          _purchases = snapshot.docs
              .map((doc) => Product.fromJson(doc.data()))
              .toList();
          notifyListeners();
        });
  }

  List<Product> get purchases => List.unmodifiable(_purchases);

  Future<void> addPurchase(Product product) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      // Check for duplicates before adding
      final doc = await _firestore
          .collection('users')
          .doc(user.id)
          .collection('purchases')
          .doc(product.id)
          .get();

      if (!doc.exists) {
        await _firestore
            .collection('users')
            .doc(user.id)
            .collection('purchases')
            .doc(product.id)
            .set(product.toJson());
      }
    } catch (e) {
      debugPrint('Error adding purchase to Firestore: $e');
    }
  }

  Future<void> clearData() async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('users')
          .doc(user.id)
          .collection('purchases')
          .get();

      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing purchases: $e');
    }
  }
}
