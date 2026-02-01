import 'package:flutter/material.dart';

import '../widgets/global_refresh_indicator.dart';
import '../data/product_repository.dart';
import '../data/purchases_repository.dart';
import '../widgets/common_widgets.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المشتريات"), centerTitle: true),
      body: ListenableBuilder(
        listenable: PurchasesRepository(),
        builder: (context, _) {
          final wonProducts = PurchasesRepository().purchases;

          if (wonProducts.isEmpty) {
            return GlobalRefreshIndicator(
              onRefresh: () async {
                await ProductRepository().refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          "لا توجد مشتريات",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "ستظهر هنا المنتجات التي فزت بها",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
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
              await ProductRepository().refresh();
            },
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: wonProducts.length,
              itemBuilder: (context, index) {
                final product = wonProducts[index];
                return ProductCard(
                  productId: product.id,
                  name: product.name,
                  price: product.price,
                  timeLeft: product.timeLeft,
                  images: product.images,
                  isDarkBg: product.isDarkBg,
                  isLocalImage: product.isLocalImage,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
