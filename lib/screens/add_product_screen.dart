import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../data/product_repository.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _startingPriceController = TextEditingController();
  final _realPriceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedEndTime;
  String _selectedStatus = 'جديد';
  bool _isOffer = false;
  final List<String> _statusOptions = ['جديد', 'مستعمل', 'أوبن بوكس', 'نقص'];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _startingPriceController.dispose();
    _realPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectEndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedEndTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<List<String>> _uploadImages(String productId) async {
    final List<String> urls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];

      try {
        debugPrint(
          '🔄 جاري رفع الصورة ${i + 1} من ${_selectedImages.length}...',
        );

        // Create file name
        final fileName = '${productId}/image_$i.jpg';

        // Upload file to Supabase Storage
        final bytes = await image.readAsBytes();
        await Supabase.instance.client.storage
            .from('product_images') // Requires bucket named 'product_images'
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );

        // Get public URL
        final imageUrl = Supabase.instance.client.storage
            .from('product_images')
            .getPublicUrl(fileName);

        urls.add(imageUrl);

        debugPrint('✅ تم رفع الصورة ${i + 1} بنجاح!');
        debugPrint('📎 الرابط: $imageUrl');
      } catch (e) {
        debugPrint('❌ خطأ في رفع الصورة ${i + 1}: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'فشل رفع الصورة ${i + 1} إلى Firebase: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        rethrow;
      }
    }

    return urls;
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار صورة واحدة على الأقل')),
        );
        return;
      }

      if (_selectedEndTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار وقت انتهاء المزاد')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final productId = DateTime.now().millisecondsSinceEpoch.toString();

        // 1. Upload Images to Firebase Storage
        final List<String> imageUrls = await _uploadImages(productId);

        // 2. Prepare Product Object
        final price = _priceController.text.trim();
        final startingPrice = _startingPriceController.text.trim();
        final realPrice = _realPriceController.text.trim();

        final newProduct = Product(
          id: productId,
          name: _nameController.text,
          price: price.startsWith('\$') ? price : '\$ $price',
          startingPrice: startingPrice.startsWith('\$')
              ? startingPrice
              : '\$ $startingPrice',
          realPrice: realPrice.isEmpty
              ? null
              : (realPrice.startsWith('\$') ? realPrice : '\$ $realPrice'),
          endTime: _selectedEndTime,
          images: imageUrls,
          isDarkBg: false,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          status: _selectedStatus,
          isLocalImage: false,
          isOffer: _isOffer,
          bannerImage: _isOffer && imageUrls.isNotEmpty
              ? imageUrls.first
              : null,
          category: 'عام',
          views: 0,
          bids: 0,
          timestamp: DateTime.now(),
        );

        await ProductRepository().addProduct(newProduct);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة المنتج ورفع الصور بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء الرفع: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إضافة منتج جديد")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Images Grid Section
              if (_selectedImages.isNotEmpty) ...[
                const Text(
                  'الصور المختارة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                    _selectedImages[index].path,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Image.file(
                                    File(_selectedImages[index].path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 5,
                          right: 5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Add Images Button
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  _selectedImages.isEmpty
                      ? 'إضافة صور المنتج'
                      : 'إضافة المزيد من الصور',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Name Input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال اسم المنتج' : null,
              ),
              const SizedBox(height: 15),

              // Starting Price Input
              TextFormField(
                controller: _startingPriceController,
                decoration: const InputDecoration(
                  labelText: 'سعر البداية',
                  hintText: 'مثال: 50',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال سعر البداية' : null,
              ),
              const SizedBox(height: 15),

              // Current Price Input
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر الحالي (الابتدائي)',
                  hintText: 'مثال: 50',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'عادة يكون نفس سعر البداية في البداية',
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال السعر الحالي' : null,
              ),
              const SizedBox(height: 15),

              // Real Price Input
              TextFormField(
                controller: _realPriceController,
                decoration: const InputDecoration(
                  labelText: 'سعر المنتج الحقيقي (اختياري)',
                  hintText: 'مثال: 100',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                  helperText: 'السعر الحقيقي للمنتج في السوق',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),

              // Auction End Time
              ListTile(
                title: const Text('وقت انتهاء المزاد'),
                subtitle: Text(
                  _selectedEndTime == null
                      ? 'لم يتم الاختيار'
                      : '${_selectedEndTime!.year}-${_selectedEndTime!.month.toString().padLeft(2, '0')}-${_selectedEndTime!.day.toString().padLeft(2, '0')} '
                            '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectEndTime,
                tileColor: Colors.grey[850],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              const SizedBox(height: 15),

              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'حالة المنتج',
                  border: OutlineInputBorder(),
                ),
                items: _statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 15),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'الوصف (اختياري)',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 15),

              // isOffer Toggle
              SwitchListTile(
                title: const Text(
                  'عرض في شريط العروض العلوي (التايتل)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'سيظهر هذا المنتج في الجزء المتحرك أعلى الصفحة الرئيسية إذا تم التفعيل',
                  style: TextStyle(fontSize: 12),
                ),
                value: _isOffer,
                onChanged: (bool value) {
                  setState(() {
                    _isOffer = value;
                  });
                },
                secondary: Icon(
                  Icons.view_carousel,
                  color: _isOffer ? Colors.orangeAccent : Colors.grey,
                ),
                activeThumbColor: Colors.orangeAccent,
              ),

              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'جاري الرفع والحفظ...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : const Text('حفظ المنتج', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
