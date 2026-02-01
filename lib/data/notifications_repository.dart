import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/notification.dart';
import 'auth_repository.dart';

class NotificationsRepository extends ChangeNotifier {
  static final NotificationsRepository _instance =
      NotificationsRepository._internal();
  factory NotificationsRepository() => _instance;
  NotificationsRepository._internal();

  final _supabase = Supabase.instance.client;
  List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen to notifications for the CURRENT user
    AuthRepository().addListener(_setupUserListener);
    _setupUserListener();

    _isInitialized = true;
  }

  void _setupUserListener() {
    final user = AuthRepository().currentUser;
    if (user == null) {
      _notifications = [];
      notifyListeners();
      return;
    }

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('timestamp', ascending: false)
        .listen((data) {
          _notifications = data
              .map((json) => AppNotification.fromJson(json))
              .toList();
          notifyListeners();
        });
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? productId,
  }) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      productId: productId,
    );

    // Map to Supabase table structure
    final data = notification.toJson();
    data['user_id'] = user.id; // Add foreign key

    try {
      await _supabase.from('notifications').insert(data);
    } catch (e) {
      debugPrint('Error adding notification to Supabase: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('notifications')
          .update({'isRead': true})
          .eq('id', id);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'isRead': true})
          .eq('user_id', user.id)
          .eq('isRead', false);
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _supabase.from('notifications').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAll() async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      await _supabase.from('notifications').delete().eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }
}
