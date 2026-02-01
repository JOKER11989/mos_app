import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import 'auth_repository.dart';

class NotificationsRepository extends ChangeNotifier {
  static final NotificationsRepository _instance =
      NotificationsRepository._internal();
  factory NotificationsRepository() => _instance;
  NotificationsRepository._internal();

  final _firestore = FirebaseFirestore.instance;
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

    // Real-time listener for this user's notifications
    _firestore
        .collection('users')
        .doc(user.id)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          _notifications = snapshot.docs
              .map((doc) => AppNotification.fromJson(doc.data()))
              .toList();
          notifyListeners();

          // We can also trigger cleanup here locally if needed,
          // but better to have a cloud function or TTL index in Firestore.
          _cleanOldNotificationsLocally();
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

    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toJson());
    } catch (e) {
      debugPrint('Error adding notification to Firestore: $e');
    }
  }

  // مسح الإشعارات التي مر عليها أكثر من 30 يوم (محلياً لتقليل الزحام، ويُفضل استخدام TTL في فيرببيس)
  void _cleanOldNotificationsLocally() {
    // Note: For a real production app with Firestore,
    // you should use a "TTL" (Time To Live) policy in the Firestore console
    // on the 'timestamp' field to auto-delete old docs.
  }

  Future<void> markAsRead(String id) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshots.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> clearAll() async {
    final user = AuthRepository().currentUser;
    if (user == null) return;

    try {
      final batch = _firestore.batch();
      final snapshots = await _firestore
          .collection('users')
          .doc(user.id)
          .collection('notifications')
          .get();

      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }
}
