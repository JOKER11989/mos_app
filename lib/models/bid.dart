import 'package:cloud_firestore/cloud_firestore.dart';

class Bid {
  final String id;
  final String productId;
  final String userId;
  final String bidderName;
  final int amount;
  final DateTime timestamp;

  Bid({
    required this.id,
    required this.productId,
    required this.userId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  Bid copyWith({
    String? id,
    String? productId,
    String? userId,
    String? bidderName,
    int? amount,
    DateTime? timestamp,
  }) {
    return Bid(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      bidderName: bidderName ?? this.bidderName,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'bidderName': bidderName,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'],
      productId: json['productId'],
      userId: json['userId'],
      bidderName: json['bidderName'],
      amount: json['amount'],
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp']),
    );
  }
}
