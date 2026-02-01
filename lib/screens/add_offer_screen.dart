import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/product_repository.dart';
import '../models/product.dart';

class AddOfferScreen extends StatefulWidget {
  final Product? product; // If provided, we are editing

  const AddOfferScreen({super.key, this.product});

  @override
  State<AddOfferScreen> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  final ImagePicker _picker = ImagePicker();

  // Banner Image
  String? _currentBannerImage;
  XFile? _newBannerImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product?.name ?? '');
    _currentBannerImage = widget.product?.bannerImage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickBannerImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newBannerImage = image;
      });
    }
  }

  Future<void> _saveOffer() async {
    if (_formKey.currentState!.validate()) {
      // Validation: Must have a banner image (either existing or new)
      if (_currentBannerImage == null && _newBannerImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار صورة للبانر'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final productId =
            widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString();

        // Use local path or existing URL
        final bannerUrl = _newBannerImage?.path ?? _currentBannerImage;

        if (widget.product != null) {
          // --- EDIT ---
          final updatedProduct = widget.product!.copyWith(
            name: _titleController.text,
            bannerImage: bannerUrl,
            isLocalImage: _newBannerImage != null,
          );
          await ProductRepository().updateProduct(updatedProduct);
        } else {
          // --- ADD ---
          final newProduct = Product(
            id: productId,
            name: _titleController.text,
            price: '0', // Not used for offers
            startingPrice: '0',
            endTime: DateTime.now().add(const Duration(days: 365)),
            images: [],
            isDarkBg: false,
            description: null,
            status: 'Available',
            isLocalImage: true,
            isOffer: true,
            views: 0,
            bids: 0,
            timestamp: DateTime.now(),
            bannerImage: bannerUrl,
          );
          await ProductRepository().addProduct(newProduct);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.product != null ? 'تم تعديل العرض' : 'تم إضافة العرض',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
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
      appBar: AppBar(
        title: Text(widget.product != null ? "تعديل العرض" : "إضافة عرض جديد"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Banner Image Picker ---
              GestureDetector(
                onTap: _pickBannerImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purpleAccent),
                  ),
                  child: _newBannerImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  _newBannerImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_newBannerImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : (_currentBannerImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    _currentBannerImage!.startsWith('http') ||
                                        kIsWeb &&
                                            !_currentBannerImage!.startsWith(
                                              '/',
                                            ) // Basic check, better relies on context logic
                                    ? Image.network(
                                        _currentBannerImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.error),
                                      )
                                    : Image.file(
                                        File(_currentBannerImage!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) =>
                                            const Icon(Icons.error),
                                      ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "اضغط لإضافة صورة البانر",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 20),

              // --- Title Input ---
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان العرض',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'الرجاء إدخال عنوان للعرض' : null,
              ),
              const SizedBox(height: 30),

              // --- Save Button ---
              ElevatedButton(
                onPressed: _isSaving ? null : _saveOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'جاري الحفظ...',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        widget.product != null
                            ? 'حفظ التعديلات'
                            : 'إضافة العرض',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
