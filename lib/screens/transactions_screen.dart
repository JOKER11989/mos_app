import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/global_refresh_indicator.dart';
import '../data/auth_repository.dart';
import '../data/bids_repository.dart';
import '../data/product_repository.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المعاملات"), centerTitle: true),
      body: ListenableBuilder(
        listenable: Listenable.merge([AuthRepository(), BidsRepository()]),
        builder: (context, _) {
          final user = AuthRepository().currentUser;
          if (user == null) {
            return const Center(child: Text("يرجى تسجيل الدخول أولاً"));
          }

          final repo = BidsRepository();
          final userBids = repo.getUserBids(user.id);

          if (userBids.isEmpty) {
            return GlobalRefreshIndicator(
              onRefresh: () async {
                await repo.initialize();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          "سجل المعاملات فارغ حالياً",
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
              itemCount: userBids.length,
              itemBuilder: (context, index) {
                final bid = userBids[index];
                final products = ProductRepository().products;
                final productMatches = products
                    .where((p) => p.id == bid.productId)
                    .toList();

                if (productMatches.isEmpty) {
                  return _buildTransactionCard(
                    title: "منتج غير موجود",
                    amount: bid.amount,
                    time: _formatTimestamp(bid.timestamp),
                    imageUrl: null,
                    isLocalImage: false,
                  );
                }
                final product = productMatches.first;

                return _buildTransactionCard(
                  title: product.name,
                  amount: bid.amount,
                  time: _formatTimestamp(bid.timestamp),
                  imageUrl: product.images.isNotEmpty
                      ? product.images.first
                      : null,
                  isLocalImage: product.isLocalImage,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required int amount,
    required String time,
    required String? imageUrl,
    required bool isLocalImage,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: imageUrl != null
                ? DecorationImage(
                    image: isLocalImage
                        ? (kIsWeb
                                  ? NetworkImage(imageUrl)
                                  : FileImage(File(imageUrl)))
                              as ImageProvider
                        : (imageUrl.startsWith('http')
                              ? NetworkImage(imageUrl)
                              : AssetImage(imageUrl) as ImageProvider),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          child: imageUrl == null
              ? const Icon(Icons.image, color: Colors.grey)
              : null,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
        ),
        subtitle: Text(
          time,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.right,
        ),
        trailing: Text(
          "\$$amount",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blueAccent,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
  }
}
