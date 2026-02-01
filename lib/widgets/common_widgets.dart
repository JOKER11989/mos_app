import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../screens/product_details_screen.dart';
import '../data/product_repository.dart';

// بطاقة المنتج في الشبكة الرئيسية
class ProductCard extends StatefulWidget {
  final String productId;
  final String name, price, timeLeft;
  final List<String> images;
  final bool isDarkBg;
  final bool isLocalImage;

  const ProductCard({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.timeLeft,
    required this.images,
    this.isDarkBg = false,
    this.isLocalImage = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  Timer? _timer;
  String _timeRemaining = '00h 00m 00s';
  bool _auctionEnded = false;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        oldWidget.timeLeft != widget.timeLeft) {
      _timer?.cancel();
      _initTimer();
    }
  }

  void _initTimer() {
    final product = ProductRepository().products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => ProductRepository().products.first,
    );
    _startCountdown(product.endTime);
  }

  void _startCountdown(DateTime? endTime) {
    if (endTime == null) {
      setState(() {
        _timeRemaining = widget.timeLeft;
        _auctionEnded = true;
      });
      return;
    }

    _updateTimeRemaining(endTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeRemaining(endTime);
    });
  }

  void _updateTimeRemaining(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);

    if (difference.isNegative) {
      if (mounted) {
        setState(() {
          _timeRemaining = '00h 00m 00s';
          _auctionEnded = true;
        });
      }
      _timer?.cancel();
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);

      if (mounted) {
        setState(() {
          _timeRemaining =
              '${hours.toString().padLeft(2, '0')}h '
              '${minutes.toString().padLeft(2, '0')}m '
              '${seconds.toString().padLeft(2, '0')}s';
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // عند الضغط ننتقل لصفحة التفاصيل
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(
            productId: widget.productId,
            name: widget.name,
            price: widget.price,
            timeLeft: widget.timeLeft,
            images: widget.images,
            isLocalImage: widget.isLocalImage,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // صورة المنتج
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isDarkBg
                      ? Colors.white
                      : const Color(0xFF1E1E1E),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: widget.images.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : (widget.isLocalImage
                            ? (kIsWeb
                                  ? Image.network(
                                      widget.images.first,
                                      fit: BoxFit.contain,
                                      loadingBuilder:
                                          (context, child, progress) {
                                            if (progress == null) return child;
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            );
                                          },
                                    )
                                  : Image.file(
                                      File(widget.images.first),
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            );
                                          },
                                    ))
                            : Image.network(
                                widget.images.first,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('❌ خطأ في تحميل الصورة: $error');
                                  debugPrint(
                                    '📎 الرابط: ${widget.images.first}',
                                  );
                                  return Container(
                                    color: Colors.grey[900],
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.broken_image,
                                              color: Colors.red,
                                              size: 30,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              widget.images.first,
                                              style: const TextStyle(
                                                color: Colors.yellow,
                                                fontSize: 8,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'الرابط لا يعمل',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),
                ),
              ),
            ),
            // تفاصيل المنتج أسفل الصورة
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Text(
                    widget.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.price,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // عداد الوقت الأخضر الصغير
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _auctionEnded ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _timeRemaining,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

// شريحة التصنيف (مثل Winter, Luxury)
class CategoryChip extends StatelessWidget {
  final String label;
  const CategoryChip({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }
}

// عنصر في القائمة الجانبية
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const DrawerItem({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: () {},
    );
  }
}

// زر اختيار اللغة
class LanguageBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  const LanguageBtn({super.key, required this.label, this.isSelected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // إذا تم اختياره يكون الإطار أزرق، وإلا رمادي
        border: Border.all(
          color: isSelected ? Colors.blueAccent : Colors.grey.shade700,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.grey),
      ),
    );
  }
}
