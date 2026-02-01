import 'package:flutter/material.dart';
import '../widgets/global_refresh_indicator.dart';
import '../data/notifications_repository.dart';
import '../data/product_repository.dart';
import '../models/notification.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الإشعارات"), centerTitle: true),
      body: ListenableBuilder(
        listenable: NotificationsRepository(),
        builder: (context, child) {
          // Trigger check for ended auctions when viewing notifications
          ProductRepository().checkEndedAuctions();

          final repo = NotificationsRepository();
          final notifications = repo.notifications;

          if (notifications.isEmpty) {
            return GlobalRefreshIndicator(
              onRefresh: () async {
                await repo.initialize();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 100,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "لا توجد إشعارات حتى الآن",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return GlobalRefreshIndicator(
            onRefresh: () async {
              await repo.initialize();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      if (!notification.isRead) {
                        repo.markAsRead(notification.id);
                      }
                    },
                    child: _buildNotificationCard(
                      icon: _getIconForType(notification.type),
                      title: notification.title,
                      message: notification.message,
                      time: _formatTimestamp(notification.timestamp),
                      isRead: notification.isRead,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF2C3E50).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRead ? Colors.grey.shade800 : Colors.blueAccent,
          width: isRead ? 1 : 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.outbid:
        return Icons.trending_up;
      case NotificationType.auctionEnd:
        return Icons.gavel;
      case NotificationType.won:
        return Icons.emoji_events;
      case NotificationType.info:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // حساب الأيام المتبقية للحذف (من أصل 30 يوم)
    final daysPassed = difference.inDays;
    final daysLeft = 30 - daysPassed;
    final deleteInfo = daysLeft > 0
        ? " • يتبقى $daysLeft يوم للحذف"
        : " • يحذف اليوم";

    if (difference.inMinutes < 60) {
      return "منذ ${difference.inMinutes} دقيقة$deleteInfo";
    } else if (difference.inHours < 24) {
      return "منذ ${difference.inHours} ساعة$deleteInfo";
    } else {
      return "${DateFormat('yyyy-MM-dd').format(timestamp)}$deleteInfo";
    }
  }
}
