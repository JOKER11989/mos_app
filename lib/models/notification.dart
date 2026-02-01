import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  outbid, // تم تجاوز المزايدة
  auctionEnd, // انتهى المزاد
  won, // فزت بالمزاد
  info, // إشعار عام
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? productId;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.productId,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? productId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      productId: productId ?? this.productId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.index,
      'isRead': isRead,
      'productId': productId,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
      type: NotificationType.values[json['type']],
      isRead: json['isRead'] ?? false,
      productId: json['productId'],
    );
  }
}
