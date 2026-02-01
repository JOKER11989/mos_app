import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'auth_repository.dart';

class FavoritesRepository extends ChangeNotifier {
  static final FavoritesRepository _instance = FavoritesRepository._internal();
  factory FavoritesRepository() => _instance;
  FavoritesRepository._internal();

  final _supabase = Supabase.instance.client;
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

    _fetchFavorites(user.id);

    // Optional: Set up real-time listener if table exists and RLS allows
    // For now, simple fetch is safer to avoid build errors
  }

  Future<void> _fetchFavorites(String userId) async {
    try {
      final data = await _supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', userId);

      _favoriteIds.clear();
      for (var item in data) {
        _favoriteIds.add(item['product_id'] as String);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  Future<void> toggleFavorite(String productId) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      if (_favoriteIds.contains(productId)) {
        // Remove
        await _supabase.from('favorites').delete().match({
          'user_id': user.id,
          'product_id': productId,
        });

        _favoriteIds.remove(productId);
      } else {
        // Add
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'product_id': productId,
          'added_at': DateTime.now().toIso8601String(),
        });

        _favoriteIds.add(productId);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert local state on error if needed, or just log
    }
  }
}
