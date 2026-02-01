import 'package:flutter/material.dart';
import '../widgets/global_refresh_indicator.dart';
import '../data/favorites_repository.dart';
import '../data/product_repository.dart';
import '../widgets/common_widgets.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("المفضلة"), centerTitle: true),
      body: GlobalRefreshIndicator(
        onRefresh: () async {
          await ProductRepository().refresh();
        },
        child: ListenableBuilder(
          listenable: FavoritesRepository(),
          builder: (context, child) {
            final favoriteIds = FavoritesRepository().favoriteIds;
            final favoriteProducts = ProductRepository().products
                .where((product) => favoriteIds.contains(product.id))
                .toList();

            if (favoriteIds.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 100,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "لا توجد منتجات مفضلة",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: favoriteProducts.length,
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];
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
            );
          },
        ),
      ),
    );
  }
}
