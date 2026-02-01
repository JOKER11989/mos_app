import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/global_refresh_indicator.dart';
import '../widgets/common_widgets.dart';
import '../widgets/offers_carousel.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

// ==========================================
// --- 1. الصفحة الرئيسية (كما في الصورة الثانية) ---
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'جميع المنتجات';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استدعاء القائمة الجانبية
      drawer: AppDrawer(),
      appBar: AppBar(
        // تخصيص عنوان الـ AppBar ليصبح شريط بحث
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C), // لون خلفية شريط البحث
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            textAlign: TextAlign.right, // محاذاة النص لليمين للعربية
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: const InputDecoration(
              hintText: '...البحث عن المنتجات',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: GlobalRefreshIndicator(
        onRefresh: () async {
          await ProductRepository().refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- شريط العروض المتحرك (Offers Carousel) ---
              ListenableBuilder(
                listenable: ProductRepository(),
                builder: (context, child) {
                  final offers = ProductRepository().offerProducts;
                  return OffersCarousel(products: offers);
                },
              ),

              // --- شريط التصنيفات والفلاتر ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, // محاذاة لليمين
                  children: [
                    // قائمة منسدلة
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.blueAccent,
                          ),
                          dropdownColor: const Color(0xFF1E1E1E),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'Cairo', // فرض الخط إذا كان موجوداً
                          ),
                          items:
                              <String>[
                                'جميع المنتجات',
                                'اعلى المزايدات',
                                'إلكتروني',
                                'منزلي',
                                'أطفال',
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCategory = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- شبكة المنتجات (GridView) ---
              ListenableBuilder(
                listenable: ProductRepository(),
                builder: (context, child) {
                  final allProducts = ProductRepository().regularProducts;
                  List<Product> products = allProducts
                      .where(
                        (p) => p.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();

                  // تطبيق الفلترة حسب التصنيف
                  if (_selectedCategory == 'اعلى المزايدات') {
                    // ترتيب حسب عدد المزايدات (الأكثر أولاً)
                    products.sort((a, b) => b.bids.compareTo(a.bids));
                  } else if (_selectedCategory != 'جميع المنتجات') {
                    // تصفية حسب التصنيف المحدد
                    products = products
                        .where((p) => p.category == _selectedCategory)
                        .toList();
                  }

                  if (products.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              "لا توجد نتائج",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedCategory != 'جميع المنتجات')
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'جميع المنتجات';
                                  });
                                },
                                child: const Text("إظهار الكل"),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true, // مهم جداً داخل SingleChildScrollView
                    physics:
                        const NeverScrollableScrollPhysics(), // تعطيل سكرول الشبكة الداخلي
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // عمودين
                          childAspectRatio: 0.75, // نسبة الطول للعرض للبطاقة
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: products.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final product = products[index];
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
            ],
          ),
        ),
      ),
      // --- الشريط السفلي (Bottom Navigation Bar) ---
    );
  }
}
