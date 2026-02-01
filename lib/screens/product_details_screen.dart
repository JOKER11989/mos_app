import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../data/favorites_repository.dart';
import '../data/product_repository.dart';
import '../data/bids_repository.dart';
import '../data/auth_repository.dart';
import '../data/notifications_repository.dart';
import '../models/notification.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  final String name;
  final String price;
  final String timeLeft;
  final List<String> images;
  final bool isLocalImage;

  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.name,
    required this.price,
    required this.timeLeft,
    required this.images,
    this.isLocalImage = false,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // إضافة PageController للتحكم في PageView
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late int _bidAmount; // مبلغ المزايدة الكامل
  late String _currentPrice;
  late String _startingPrice;
  late int _currentBids;
  late int _currentViews;

  // Countdown timer variables
  Timer? _timer;
  String _timeRemaining = '00h 00m 00s';
  bool _auctionEnded = false;

  @override
  void initState() {
    super.initState();
    // Get product from repository to get current data
    final product = ProductRepository().products.firstWhere(
      (p) => p.id == widget.productId,
    );
    _currentPrice = product.price;
    _startingPrice = product.startingPrice;
    _currentBids = product.bids;
    _currentViews = product.views;

    // Initialize bid amount to current price + 1
    final currentPriceValue =
        int.tryParse(_currentPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    _bidAmount = currentPriceValue + 1;

    // Start countdown timer
    _startCountdown(product.endTime);
  }

  void _startCountdown(DateTime? endTime) {
    if (endTime == null) {
      setState(() {
        _timeRemaining = '00h 00m 00s';
        _auctionEnded = true;
      });
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = endTime.difference(now);

      if (difference.isNegative) {
        setState(() {
          _timeRemaining = '00h 00m 00s';
          _auctionEnded = true;
        });
        timer.cancel();
      } else {
        final hours = difference.inHours;
        final minutes = difference.inMinutes.remainder(60);
        final seconds = difference.inSeconds.remainder(60);

        setState(() {
          _timeRemaining =
              '${hours.toString().padLeft(2, '0')}h '
              '${minutes.toString().padLeft(2, '0')}m '
              '${seconds.toString().padLeft(2, '0')}s';
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // تنظيف الـ controller
    _timer?.cancel(); // إيقاف المؤقت
    super.dispose();
  }

  void _placeBid() {
    // Check if auction has ended
    if (_auctionEnded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('انتهى وقت المزاد على هذا المنتج'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is logged in
    final currentUser = AuthRepository().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً للمزايدة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Extract current price value
    final currentPriceValue =
        int.tryParse(_currentPrice.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    // Check if bid is higher than current price
    if (_bidAmount <= currentPriceValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يجب أن تكون المزايدة أعلى من السعر الحالي (\$$currentPriceValue)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      final actualBidAmount = _bidAmount;
      _currentPrice = '\$$actualBidAmount';
      _currentBids++;

      // Update in repository - Get fresh product instance
      final product = ProductRepository().products.firstWhere(
        (p) => p.id == widget.productId,
      );

      final updatedProduct = product.copyWith(
        price: _currentPrice,
        bids: _currentBids,
      );
      ProductRepository().updateProduct(updatedProduct);

      // تسجيل المزايدة في سجل المزايدات العام
      BidsRepository().addBid(
        productId: widget.productId,
        userId: currentUser.id,
        bidderName: currentUser.name,
        amount: actualBidAmount,
      );

      // تحضير العداد للمزايدة التالية (تلقائياً السعر الحالي + 1)
      _bidAmount = actualBidAmount + 1;

      // إرسال إشعار للمستخدم
      NotificationsRepository().addNotification(
        title: "مزايدة ناجحة",
        message:
            "لقد قمت بالمزايدة بنجاح على ${product.name} بمبلغ \$$actualBidAmount",
        type: NotificationType.outbid,
        productId: widget.productId,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم المزايدة! السعر الجديد: $_currentPrice'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareProduct() {
    Share.share(
      'تحقق من هذا المنتج الرائع!\n\n'
      '${widget.name}\n'
      'السعر الحالي: $_currentPrice\n'
      'الوقت المتبقي: ${widget.timeLeft}',
      subject: widget.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = ProductRepository().products.firstWhere(
      (p) => p.id == widget.productId,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Product Details"),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: FavoritesRepository(),
            builder: (context, child) {
              final isFavorite = FavoritesRepository().isFavorite(
                widget.productId,
              );
              return IconButton(
                onPressed: () {
                  FavoritesRepository().toggleFavorite(widget.productId);
                },
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: ProductRepository(),
        builder: (context, child) {
          final productFromRepo = ProductRepository().products.firstWhere(
            (p) => p.id == widget.productId,
            orElse: () => product,
          );

          // Update local state variables from repo if they diverged
          _currentPrice = productFromRepo.price;
          _startingPrice = productFromRepo.startingPrice;
          _currentBids = productFromRepo.bids;
          _currentViews = productFromRepo.views;

          return SingleChildScrollView(
            child: Column(
              children: [
                // قسم الصور مع PageView
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: widget.images.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController, // ربط الـ Controller
                              itemCount: widget.images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Container(
                                  color: Colors.white,
                                  child: widget.isLocalImage
                                      ? (kIsWeb
                                            ? Image.network(
                                                widget.images[index],
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 100,
                                                    ),
                                              )
                                            : Image.file(
                                                File(widget.images[index]),
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 100,
                                                    ),
                                              ))
                                      : Image.network(
                                          widget.images[index],
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => const Icon(
                                            Icons.broken_image,
                                            size: 100,
                                          ),
                                        ),
                                );
                              },
                            )
                          : const Center(child: Icon(Icons.image, size: 100)),
                    ),

                    // أزرار التنقل (الأسهم)
                    if (widget.images.length > 1) ...[
                      // السهم الأيسر
                      Positioned(
                        left: 10,
                        top: 0,
                        bottom: 40,
                        child: Center(
                          child: IconButton(
                            onPressed: _currentImageIndex > 0
                                ? () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // السهم الأيمن
                      Positioned(
                        right: 10,
                        top: 0,
                        bottom: 40,
                        child: Center(
                          child: IconButton(
                            onPressed:
                                _currentImageIndex < widget.images.length - 1
                                ? () {
                                    _pageController.nextPage(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // نقاط التمرير (Indicators)
                      if (widget.images.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index == _currentImageIndex
                                      ? Colors.blueAccent
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: _shareProduct,
                            icon: const Icon(Icons.share_outlined),
                          ),
                          Expanded(
                            child: Text(
                              widget.name,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // عرض السعر الأساسي والسعر الحالي
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "السعر الحالي",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _currentPrice,
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "سعر البداية",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _startingPrice,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // قسم المزايدة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _auctionEnded ? null : _placeBid,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _auctionEnded
                                  ? Colors.grey
                                  : Colors.blueAccent,
                              minimumSize: const Size(120, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _auctionEnded ? "انتهى" : "Bid",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // عداد القيمة
                          Container(
                            height: 55,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _auctionEnded
                                      ? null
                                      : () {
                                          setState(() {
                                            // Extract current price to ensure bid is always higher
                                            final currentPriceValue =
                                                int.tryParse(
                                                  _currentPrice.replaceAll(
                                                    RegExp(r'[^\d]'),
                                                    '',
                                                  ),
                                                ) ??
                                                0;
                                            if (_bidAmount >
                                                currentPriceValue + 1) {
                                              _bidAmount--;
                                            }
                                          });
                                        },
                                  icon: Icon(
                                    Icons.remove,
                                    color: _auctionEnded
                                        ? Colors.grey.shade700
                                        : Colors.grey,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: Text(
                                    '\$$_bidAmount',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: _auctionEnded
                                          ? Colors.grey.shade700
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _auctionEnded
                                      ? null
                                      : () {
                                          setState(() {
                                            _bidAmount++;
                                          });
                                        },
                                  icon: Icon(
                                    Icons.add,
                                    color: _auctionEnded
                                        ? Colors.grey.shade700
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // شريط عداد الوقت
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _auctionEnded ? Colors.red : Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              _timeRemaining,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _auctionEnded
                                  ? ":انتهى المزاد"
                                  : ":Time Remaining",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // سجل المزايدات (Bid History) - Modern Expandable Design
                      ListenableBuilder(
                        listenable: BidsRepository(),
                        builder: (context, child) {
                          final bids = BidsRepository().getBidsForProduct(
                            widget.productId,
                          );

                          if (bids.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E251E),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'لا توجد مزايدات بعد',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          }

                          final latestBid = bids.first;
                          final bidCount = bids.length;

                          return Card(
                            elevation: 4,
                            color: const Color(0xFF1E1E1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                childrenPadding: const EdgeInsets.only(
                                  bottom: 15,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${latestBid.amount}',
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      "سجل المزايدات ($bidCount)",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  "آخر مزايدة بواسطة: ${latestBid.bidderName}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 250,
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: bids.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(color: Colors.white10),
                                      itemBuilder: (context, index) {
                                        final bid = bids[index];
                                        final dateFormat = DateFormat(
                                          'HH:mm dd/MM',
                                        );
                                        final formattedDate = dateFormat.format(
                                          bid.timestamp,
                                        );
                                        final isTopBid = index == 0;

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isTopBid
                                                ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '\$${bid.amount}',
                                                    style: TextStyle(
                                                      fontSize: isTopBid
                                                          ? 16
                                                          : 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isTopBid
                                                          ? Colors.greenAccent
                                                          : Colors.white70,
                                                    ),
                                                  ),
                                                  if (isTopBid)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 5,
                                                      ),
                                                      child: Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 14,
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              // Bidder Info
                                              Row(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        bid.bidderName,
                                                        style: TextStyle(
                                                          fontWeight: isTopBid
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      Text(
                                                        formattedDate,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const CircleAvatar(
                                                    backgroundColor: Color(
                                                      0xFF2C2C2C,
                                                    ),
                                                    radius: 12,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // احصائيات المشاهدات
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: ListenableBuilder(
                          listenable: BidsRepository(),
                          builder: (context, child) {
                            final uniqueBidders = BidsRepository()
                                .getUniqueBiddersCountForProduct(
                                  widget.productId,
                                );

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  Icons.remove_red_eye_outlined,
                                  _currentViews.toString(),
                                  "Views",
                                ),
                                _buildStatItem(
                                  Icons.people_outline,
                                  uniqueBidders.toString(),
                                  "Bidders",
                                ),
                                _buildStatItem(
                                  Icons.gavel_outlined,
                                  BidsRepository()
                                      .getBidsForProduct(widget.productId)
                                      .length
                                      .toString(),
                                  "Bids",
                                ),
                                _buildStatusItem(product.status),
                              ],
                            );
                          },
                        ),
                      ),

                      const Divider(color: Colors.grey),
                      const SizedBox(height: 10),

                      // عرض السعر الحقيقي إذا كان موجوداً
                      if (product.realPrice != null &&
                          product.realPrice!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2C3A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.realPrice!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                              const Text(
                                "سعر المنتج الحقيقي",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                      ],

                      const Text(
                        "تفاصيل المنتج",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // عرض الوصف إذا كان موجوداً
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2C3A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product.description!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // تنبيه الضمان
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2C3A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              "هذا المنتج بضمان 7 يوماً.",
                              style: TextStyle(color: Colors.blue),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.info_outline, color: Colors.blue),
                          ],
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
  }

  Widget _buildStatItem(IconData icon, String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 5),
              Icon(icon, color: Colors.grey, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'جديد':
        statusColor = Colors.green;
        statusIcon = Icons.new_releases;
        break;
      case 'مستعمل':
        statusColor = Colors.orange;
        statusIcon = Icons.recycling;
        break;
      case 'أوبن بوكس':
        statusColor = Colors.blue;
        statusIcon = Icons.inventory_2;
        break;
      case 'نقص':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text(
            "الحالة",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 5),
              Icon(statusIcon, color: statusColor, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
