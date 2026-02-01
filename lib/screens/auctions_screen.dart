import 'package:flutter/material.dart';
import '../widgets/global_refresh_indicator.dart';
import '../data/product_repository.dart';
import '../data/bids_repository.dart';
import '../widgets/common_widgets.dart';

class AuctionsScreen extends StatelessWidget {
  const AuctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("المناقصات الخاصة بي"), // Updated Title
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: BidsRepository(), // Listen to bids changes
        builder: (context, child) {
          final bidsRepo = BidsRepository();
          final products = ProductRepository().activeProducts;

          // Filter products to show only those user bid on
          final myAuctionProducts = products.where((product) {
            return bidsRepo.hasBidOn(product.id);
          }).toList();

          if (myAuctionProducts.isEmpty) {
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
                        Icon(Icons.gavel, size: 100, color: Colors.grey),
                        SizedBox(height: 20),
                        Text(
                          "لم تقم بالمزايدة على أي منتج بعد",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "المزايدات التي تشارك فيها ستظهر هنا",
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
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: myAuctionProducts.length,
              itemBuilder: (context, index) {
                final product = myAuctionProducts[index];
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
