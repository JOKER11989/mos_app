import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/auth_repository.dart';
import '../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _regionController;
  File? _selectedImage;
  String? _currentImagePath;

  @override
  void initState() {
    super.initState();
    final user = AuthRepository().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _regionController = TextEditingController(text: user?.region ?? '');
    _currentImagePath = user?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = AuthRepository().currentUser;
      if (currentUser != null) {
        String? finalImagePath = _currentImagePath;

        // If a new image is selected, save it permanently
        if (_selectedImage != null) {
          if (!kIsWeb) {
            try {
              final appDir = await getApplicationDocumentsDirectory();
              final fileName = p.basename(_selectedImage!.path);
              final savedImage = await _selectedImage!.copy(
                '${appDir.path}/$fileName',
              );
              finalImagePath = savedImage.path;
            } catch (e) {
              debugPrint('Error saving image: $e');
              // Fallback to the temporary path if saving fails, but warn
              finalImagePath = _selectedImage!.path;
            }
          } else {
            // On web, we can't copy files to app dir like this.
            // Just use the path (blob url) directly for the session.
            finalImagePath = _selectedImage!.path;
          }
        }

        final updatedUser = User(
          id: currentUser.id,
          name: _nameController.text,
          phone: _phoneController.text,
          address: _addressController.text.isNotEmpty
              ? _addressController.text
              : null,
          region: _regionController.text.isNotEmpty
              ? _regionController.text
              : null,
          nearestPoint: currentUser.nearestPoint,
          isAdmin: currentUser.isAdmin,
          password: currentUser.password,
          imagePath: finalImagePath,
        );

        await AuthRepository().updateUser(updatedUser);

        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: ClipOval(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: _selectedImage != null
                              ? (kIsWeb
                                    ? Image.network(
                                        _selectedImage!.path,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              );
                                            },
                                      )
                                    : Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              );
                                            },
                                      ))
                              : (_currentImagePath != null
                                    ? (kIsWeb
                                          ? Image.network(
                                              _currentImagePath!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                            )
                                          : Image.file(
                                              File(_currentImagePath!),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: Colors.grey,
                                                    );
                                                  },
                                            ))
                                    : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الاسم';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey[100],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال رقم الهاتف';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Region Field
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(
                  labelText: 'المنطقة',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 15),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'العنوان التفصيلي',
                  prefixIcon: const Icon(Icons.home),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey[100],
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'حفظ التغييرات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
