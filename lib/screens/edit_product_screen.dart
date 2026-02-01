import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../data/product_repository.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _startingPriceController;
  late TextEditingController _realPriceController;
  late TextEditingController _descriptionController;

  final ImagePicker _picker = ImagePicker();

  // Product Images
  List<String> _currentImages = [];
  final List<XFile> _newImages = [];

  DateTime? _selectedEndTime;
  late String _selectedStatus;
  bool _isOffer = false; // هل يظهر المنتج في قسم العروض العلوي
  final List<String> _statusOptions = ['جديد', 'مستعمل', 'أوبن بوكس', 'نقص'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.replaceAll('\$ ', '').replaceAll('\$', ''),
    );
    _startingPriceController = TextEditingController(
      text: widget.product.startingPrice
          .replaceAll('\$ ', '')
          .replaceAll('\$', ''),
    );
    _realPriceController = TextEditingController(
      text:
          widget.product.realPrice
              ?.replaceAll('\$ ', '')
              .replaceAll('\$', '') ??
          '',
    );
    _descriptionController = TextEditingController(
      text: widget.product.description ?? '',
    );

    _currentImages = List.from(widget.product.images);
    _selectedEndTime = widget.product.endTime;
    _selectedStatus = _statusOptions.contains(widget.product.status)
        ? widget.product.status
        : _statusOptions.first;
    _isOffer = widget.product.isOffer;
  }

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
        _newImages.addAll(images);
      });
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeCurrentImage(int index) {
    setState(() {
      _currentImages.removeAt(index);
    });
  }

  Future<void> _selectEndTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedEndTime ?? DateTime.now()),
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

  Future<List<String>> _uploadNewImages() async {
    final List<String> urls = [];
    // Explicitly using the bucket from google-services.json
    final storage = FirebaseStorage.instanceFor(
      bucket: 'mos-app-208ad.firebasestorage.app',
    );
    final storageRef = storage
        .ref()
        .child('products')
        .child(widget.product.id)
        .child('updates_${DateTime.now().millisecondsSinceEpoch}');

    for (int i = 0; i < _newImages.length; i++) {
      final image = _newImages[i];
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final fileRef = storageRef.child(fileName);

      debugPrint('Uploading new image $i to bucket: ${storage.bucket}');
      debugPrint('Path: ${fileRef.fullPath}');

      final metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = fileRef.putData(await image.readAsBytes(), metadata);
      } else {
        uploadTask = fileRef.putFile(File(image.path), metadata);
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            100.0 * (snapshot.bytesTransferred / snapshot.totalBytes);
        debugPrint(
          'Upload progress for new image $i: ${progress.toStringAsFixed(2)}%',
        );
      });

      // Wait for the upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        debugPrint(
          'Upload success for new image $i. Bytes: ${snapshot.totalBytes}',
        );

        // Retry logic for getDownloadURL
        String? downloadUrl;
        int retries = 0;
        while (retries < 3) {
          try {
            downloadUrl = await snapshot.ref.getDownloadURL();
            break;
          } catch (e) {
            retries++;
            debugPrint('Attempt $retries to get URL for new image failed: $e');
            if (retries < 3) {
              await Future.delayed(const Duration(seconds: 1));
            } else {
              rethrow;
            }
          }
        }

        if (downloadUrl != null) {
          debugPrint('Got URL for new image $i: $downloadUrl');
          urls.add(downloadUrl);
        }
      } else {
        debugPrint('Upload failed for image $i. State: ${snapshot.state}');
        throw Exception('فشل رفع الصورة رقم ${i + 1}');
      }
    }
    return urls;
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_currentImages.isEmpty && _newImages.isEmpty) {
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
        // 1. Upload only NEW images
        final List<String> uploadedUrls = await _uploadNewImages();

        // 2. Combine with remaining old images (which are already URLs or paths needing fix)
        // Note: If some _currentImages were local paths from previous bug, they will still fail.
        // But going forward, everything will be network URLs.
        List<String> finalImages = [..._currentImages, ...uploadedUrls];

        // 3. Parse prices
        final price = _priceController.text.trim();
        final startingPrice = _startingPriceController.text.trim();
        final realPrice = _realPriceController.text.trim();

        // 4. Create updated product
        final updatedProduct = widget.product.copyWith(
          name: _nameController.text,
          price: price.startsWith('\$') ? price : '\$ $price',
          startingPrice: startingPrice.startsWith('\$')
              ? startingPrice
              : '\$ $startingPrice',
          realPrice: realPrice.isEmpty
              ? null
              : (realPrice.startsWith('\$') ? realPrice : '\$ $realPrice'),
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          isLocalImage: false, // Force false now that we use Storage
          images: finalImages,
          endTime: _selectedEndTime,
          status: _selectedStatus,
          isOffer: _isOffer,
        );

        await ProductRepository().updateProduct(updatedProduct);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعديل المنتج ورفع الصور بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء التعديل: ${e.toString()}'),
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
      appBar: AppBar(title: const Text("تعديل المنتج")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Images Section ---
              const Text(
                'صور المنتج',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_currentImages.isNotEmpty || _newImages.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _currentImages.length + _newImages.length,
                  itemBuilder: (context, index) {
                    if (index < _currentImages.length) {
                      // Existing Image
                      final imagePath = _currentImages[index];
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
                              child:
                                  widget.product.isLocalImage &&
                                      !imagePath.startsWith('http') &&
                                      !kIsWeb
                                  ? Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.error),
                                    )
                                  : Image.network(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.error),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _removeCurrentImage(index),
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
                    } else {
                      // New Image
                      final newIndex = index - _currentImages.length;
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
                                      _newImages[newIndex].path,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Image.file(
                                      File(_newImages[newIndex].path),
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
                              onTap: () => _removeNewImage(newIndex),
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
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  (_currentImages.isEmpty && _newImages.isEmpty)
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

              // Description
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
                            'جاري الحفظ والرفع...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : const Text(
                        'حفظ التعديلات',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
