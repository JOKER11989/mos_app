import 'dart:io';
import '../widgets/global_refresh_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/product_repository.dart';

import 'add_offer_screen.dart';

class ManageOffersScreen extends StatefulWidget {
  const ManageOffersScreen({super.key});

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Title Items (Offers)")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddOfferScreen()),
          );
          setState(() {});
        },
        backgroundColor: Colors.purpleAccent,
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: ProductRepository(),
        builder: (context, child) {
          // عرض المنتجات التي تم تفعيلها كعروض فقط (isOffer = true)
          final allProducts = ProductRepository().products;
          final products = allProducts.where((p) => p.isOffer).toList();

          if (products.isEmpty) {
            return GlobalRefreshIndicator(
              onRefresh: () async {
                await ProductRepository().refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(
                    child: Text(
                      "No offers available\nAdd products from 'Manage Products' and toggle them as offers here",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return GlobalRefreshIndicator(
            onRefresh: () async {
              await ProductRepository().refresh();
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: product.isOffer
                          ? Colors.orangeAccent
                          : Colors.grey.withValues(alpha: 0.3),
                      width: product.isOffer ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 80,
                                height: 80,
                                child:
                                    (product.bannerImage != null &&
                                        product.bannerImage!.isNotEmpty)
                                    ? (product.isLocalImage
                                          ? (kIsWeb
                                                ? Image.network(
                                                    product.bannerImage!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(Icons.error),
                                                  )
                                                : Image.file(
                                                    File(product.bannerImage!),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(Icons.error),
                                                  ))
                                          : Image.network(
                                              product.bannerImage!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(Icons.error),
                                            ))
                                    : (product.images.isNotEmpty
                                          ? (product.isLocalImage
                                                ? (kIsWeb
                                                      ? Image.network(
                                                          product.images.first,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (c, e, s) =>
                                                                  const Icon(
                                                                    Icons.error,
                                                                  ),
                                                        )
                                                      : Image.file(
                                                          File(
                                                            product
                                                                .images
                                                                .first,
                                                          ),
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (c, e, s) =>
                                                                  const Icon(
                                                                    Icons.error,
                                                                  ),
                                                        ))
                                                : Image.network(
                                                    product.images.first,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(Icons.error),
                                                  ))
                                          : Container(
                                              color: Colors.grey[800],
                                              child: const Icon(Icons.image),
                                            )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            // Edit Button
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
                                        AddOfferScreen(product: product),
                                  ),
                                );
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Delete Button
                            TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Delete Product?"),
                                    content: const Text(
                                      "Are you sure you want to delete this product?",
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
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
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
