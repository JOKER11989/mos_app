class Product {
  final String id;
  final String name;
  final String price; // السعر الحالي (أعلى مزايدة)
  final String startingPrice; // سعر البداية
  final String? realPrice; // السعر الحقيقي للمنتج (سعر السوق)
  final DateTime timestamp; // وقت الإضافة
  final DateTime? endTime; // وقت انتهاء المزاد
  final List<String> images;
  final bool isDarkBg;
  final String? description;
  final int views;
  final int bids;
  final String status; // حالة المنتج: جديد، مستعمل، أوبن بوكس، نقص
  final bool isLocalImage;
  final bool isOffer; // هل يعرض في شريط العروض (التايتل)
  final String? bannerImage; // صورة الغلاف الخاصة بالعرض
  final String category; // التصنيف: إلكتروني، منزلي، أطفال، عام

  Product({
    required this.id,
    required this.name,
    required this.price,
    String? startingPrice,
    this.realPrice,
    required this.timestamp,
    this.endTime,
    required this.images,
    this.isDarkBg = false,
    this.description,
    this.views = 0,
    this.bids = 0,
    this.status = 'جديد',
    this.isLocalImage = false,
    this.isOffer = false,
    this.bannerImage,
    this.category = 'عام',
  }) : startingPrice =
           startingPrice ??
           price; // إذا لم يتم تحديد سعر البداية، استخدم السعر الحالي

  // حساب الوقت المتبقي ديناميكياً
  String get timeLeft {
    if (endTime == null) return '00h 00m 00s';

    final now = DateTime.now();
    final difference = endTime!.difference(now);

    if (difference.isNegative) return '00h 00m 00s';

    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  Product copyWith({
    String? id,
    String? name,
    String? price,
    String? startingPrice,
    String? realPrice,
    DateTime? timestamp,
    DateTime? endTime,
    List<String>? images,
    bool? isDarkBg,
    String? description,
    int? views,
    int? bids,
    String? status,
    bool? isLocalImage,
    bool? isOffer,
    String? bannerImage,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      startingPrice: startingPrice ?? this.startingPrice,
      realPrice: realPrice ?? this.realPrice,
      timestamp: timestamp ?? this.timestamp,
      endTime: endTime ?? this.endTime,
      images: images ?? this.images,
      isDarkBg: isDarkBg ?? this.isDarkBg,
      description: description ?? this.description,
      views: views ?? this.views,
      bids: bids ?? this.bids,
      status: status ?? this.status,
      isLocalImage: isLocalImage ?? this.isLocalImage,
      isOffer: isOffer ?? this.isOffer,
      bannerImage: bannerImage ?? this.bannerImage,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'startingPrice': startingPrice,
      'realPrice': realPrice,
      'timestamp': timestamp.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'images': images,
      'isDarkBg': isDarkBg,
      'description': description,
      'views': views,
      'bids': bids,
      'status': status,
      'isLocalImage': isLocalImage,
      'isOffer': isOffer,
      'bannerImage': bannerImage,
      'category': category,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'No Name',
      price: json['price']?.toString() ?? '0',
      startingPrice: json['startingPrice']?.toString(),
      realPrice: json['realPrice']?.toString(),
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(), // Fallback
      endTime: json['endTime'] is String
          ? DateTime.parse(json['endTime'])
          : null,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isDarkBg: json['isDarkBg'] ?? false,
      description: json['description']?.toString(),
      views: json['views'] is int ? json['views'] : 0,
      bids: json['bids'] is int ? json['bids'] : 0,
      status: json['status']?.toString() ?? 'جديد',
      isLocalImage: json['isLocalImage'] ?? false,
      isOffer: json['isOffer'] ?? false,
      bannerImage: json['bannerImage']?.toString(),
      category: json['category']?.toString() ?? 'عام',
    );
  }
}
