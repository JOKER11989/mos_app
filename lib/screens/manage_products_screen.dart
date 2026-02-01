import 'dart:io';
import 'dart:async';
import '../widgets/global_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import 'edit_product_screen.dart';
import 'add_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // تحديث الواجهة كل ثانية لعرض العد التنازلي
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Products")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
          setState(() {}); // Refresh list
        },
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: ProductRepository(),
        builder: (context, child) {
          // عرض المنتجات العادية فقط (بدون عروض التايتل)
          final products = ProductRepository().regularProducts;

          if (products.isEmpty) {
            return GlobalRefreshIndicator(
              onRefresh: () async {
                await ProductRepository().refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(child: Text("No products available")),
                ],
              ),
            );
          }
          return GlobalRefreshIndicator(
            onRefresh: () async {
              await ProductRepository().refresh();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: products.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  color: Colors.white10,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: product.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: product.isLocalImage
                                ? (kIsWeb
                                      ? Image.network(
                                          product.images.first,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              const Icon(Icons.error),
                                        )
                                      : Image.file(
                                          File(product.images.first),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              const Icon(Icons.error),
                                        ))
                                : Image.network(
                                    product.images.first,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) =>
                                        const Icon(Icons.error),
                                  ),
                          )
                        : const Icon(Icons.image, size: 50),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${product.price} - ${product.timeLeft}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProductScreen(product: product),
                              ),
                            );
                            setState(() {}); // Refresh list
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Delete Product?"),
                                content: const Text(
                                  "Are you sure you want to delete this item?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ProductRepository().deleteProduct(
                                        product.id,
                                      );
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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
}
