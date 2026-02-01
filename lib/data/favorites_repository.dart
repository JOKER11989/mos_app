import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_repository.dart';

class FavoritesRepository extends ChangeNotifier {
  static final FavoritesRepository _instance = FavoritesRepository._internal();
  factory FavoritesRepository() => _instance;
  FavoritesRepository._internal();

  final _firestore = FirebaseFirestore.instance;
  final Set<String> _favoriteIds = {};
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
      _favoriteIds.clear();
      notifyListeners();
      return;
    }

    // Real-time listener for this user's favorites
    _firestore
        .collection('users')
        .doc(user.id)
        .collection('favorites')
        .snapshots()
        .listen((snapshot) {
          _favoriteIds.clear();
          for (var doc in snapshot.docs) {
            _favoriteIds.add(doc.id);
          }
          notifyListeners();
        });
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(user.id)
        .collection('favorites')
        .doc(productId);

    try {
      if (_favoriteIds.contains(productId)) {
        await docRef.delete();
      } else {
        await docRef.set({'addedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }
}
