import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class OffersCarousel extends StatefulWidget {
  final List<Product> products;
  const OffersCarousel({super.key, required this.products});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < widget.products.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "No Offers Available",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.products.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final product = widget.products[index];
          return _buildOfferCard(product);
        },
      ),
    );
  }

  Widget _buildOfferCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            if (product.bannerImage != null)
              product.isLocalImage
                  ? (kIsWeb
                        ? Image.network(
                            product.bannerImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey),
                          )
                        : Image.file(
                            File(product.bannerImage!),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey),
                          ))
                  : Image.network(
                      product.bannerImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey),
                    )
            else if (product.images.isNotEmpty)
              product.isLocalImage
                  ? (kIsWeb
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey),
                          )
                        : Image.file(
                            File(product.images.first),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                Container(color: Colors.grey),
                          ))
                  : Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.grey),
                    )
            else
              Container(color: Colors.blueGrey),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
