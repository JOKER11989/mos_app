import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/product_repository.dart';
import '../data/bids_repository.dart';
import '../widgets/global_refresh_indicator.dart';
import '../models/product.dart';
import '../models/user.dart';

class ManageEndedAuctionsScreen extends StatelessWidget {
  const ManageEndedAuctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المزايدات المنتهية"),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([ProductRepository(), BidsRepository()]),
        builder: (context, child) {
          final products = ProductRepository().endedProducts;

          if (products.isEmpty) {
            return GlobalRefreshIndicator(
              onRefresh: () async {
                await ProductRepository().refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(child: Text("لا توجد مزايدات منتهية حالياً")),
                ],
              ),
            );
          }

          return GlobalRefreshIndicator(
            onRefresh: () async {
              await ProductRepository().refresh();
              await BidsRepository().initialize();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: products.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final product = products[index];
                final latestBid = BidsRepository().getLatestBidForProduct(
                  product.id,
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.all(10),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image:
                              product.isLocalImage && product.images.isNotEmpty
                              ? (kIsWeb
                                    ? NetworkImage(product.images.first)
                                    : FileImage(File(product.images.first))
                                          as ImageProvider)
                              : NetworkImage(
                                  product.images.isNotEmpty
                                      ? product.images.first
                                      : '',
                                ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          "السعر النهائي: ${product.price}",
                          style: const TextStyle(color: Colors.blueAccent),
                        ),
                        if (latestBid != null)
                          Text(
                            "الفائز: ${latestBid.bidderName}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const Text(
                            "لا توجد مزايدات",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (latestBid != null)
                          IconButton(
                            icon: const Icon(
                              Icons.contact_phone_outlined,
                              color: Colors.greenAccent,
                            ),
                            onPressed: () =>
                                _showWinnerInfo(context, latestBid.userId),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _confirmDelete(context, product),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "سجل المزايدة:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ...BidsRepository()
                                .getBidsForProduct(product.id)
                                .map(
                                  (bid) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(bid.bidderName),
                                        Text(
                                          "${bid.amount}",
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showWinnerInfo(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("جاري تحميل بيانات الفائز..."),
                ],
              ),
            );
          }

          final userData = snapshot.data;
          // Note: User.fromJson handles parsing, ensure your model matches Supabase structure
          final winner = userData != null ? User.fromJson(userData) : null;

          return AlertDialog(
            title: const Text("بيانات الفائز"),
            content: winner != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الأسم: ${winner.name}"),
                      const SizedBox(height: 10),
                      Text("رقم الهاتف: ${winner.phone}"),
                      const SizedBox(height: 10),
                      Text("المنطقة: ${winner.region ?? 'غير محدد'}"),
                      const SizedBox(height: 10),
                      Text("العنوان: ${winner.address ?? 'غير محدد'}"),
                      const SizedBox(height: 10),
                      Text("أقرب نقطة: ${winner.nearestPoint ?? 'غير محدد'}"),
                    ],
                  )
                : const Text("لم يتم العثور على بيانات المستخدم."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إغلاق"),
              ),
              if (winner != null)
                ElevatedButton.icon(
                  onPressed: () {
                    // هنا يمكن إضافة وظيفة التواصل المباشر عبر الواتساب أو الإتصال
                  },
                  icon: const Icon(Icons.call),
                  label: const Text("اتصال"),
                ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("حذف السجل"),
        content: Text(
          "هل أنت متأكد من رغبتك في حذف سجل المزايدة على ${product.name}؟",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              ProductRepository().deleteProduct(product.id);
              Navigator.pop(ctx);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
