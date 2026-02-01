import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _selectedTab = 0; // 0: User, 1: Admin
  bool _isLoginMode = true; // Toggle between Login and Register for Users

  // Admin login controllers
  final TextEditingController _adminUsernameController =
      TextEditingController();
  final TextEditingController _adminPasswordController =
      TextEditingController();
  final _adminFormKey = GlobalKey<FormState>();

  // User form controllers
  final _userFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _nearestPointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize default admin
    AuthRepository().initializeDefaultAdmin();
  }

  @override
  void dispose() {
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _nearestPointController.dispose();
    super.dispose();
  }

  void _loginAdmin() async {
    if (_adminFormKey.currentState!.validate()) {
      try {
        await AuthRepository().loginAdmin(
          _adminUsernameController.text,
          _adminPasswordController.text,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleUserSubmit() async {
    if (_userFormKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        await AuthRepository().loginUser(
          name: _isLoginMode ? 'مستخدم' : _nameController.text,
          phone: _phoneController.text,
          address: _isLoginMode ? null : _addressController.text,
          region: _isLoginMode ? null : _regionController.text,
          nearestPoint: _isLoginMode ? null : _nearestPointController.text,
        );

        if (!mounted) return;
        Navigator.pop(context); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading (if open)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(Icons.lock_person, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 30),
              Text(
                _selectedTab == 0
                    ? (_isLoginMode ? "تسجيل الدخول" : "إنشاء حساب جديد")
                    : "دخول المشرفين",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Custom Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTabItem("مستخدم", 0),
                    _buildTabItem("أدمن", 1),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTab == 0 ? _buildUserForm() : _buildAdminForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminForm() {
    return Form(
      key: _adminFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _adminUsernameController,
            label: "اسم المستخدم",
            icon: Icons.person,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            controller: _adminPasswordController,
            label: "كلمة المرور",
            icon: Icons.lock,
            isPassword: true,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _loginAdmin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "تسجيل دخول الأدمن",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () async {
              final email = _adminUsernameController.text;
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'الرجاء إدخال اسم المستخدم أو البريد الإلكتروني أولاً',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (c) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await AuthRepository().sendPasswordResetEmail(email);

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم إرسال رابط إعادة تعيين كلمة السر إلى بريدك الإلكتروني',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll("Exception: ", "")),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "هل نسيت كلمة السر؟",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserForm() {
    return Form(
      key: _userFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If Register Mode, show extra fields
          if (!_isLoginMode) ...[
            _buildTextField(
              controller: _nameController,
              label: "الاسم الكامل",
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
          ],

          _buildTextField(
            controller: _phoneController,
            label: "رقم الهاتف",
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 15),

          if (!_isLoginMode) ...[
            _buildTextField(
              controller: _addressController,
              label: "المحافظة", // Changed from "العنوان الكامل"
              icon: Icons.home,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _regionController,
              label: "المنطقة",
              icon: Icons.location_city,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _nearestPointController,
              label: "أقرب نقطة دالة",
              icon: Icons.map,
            ),
            const SizedBox(height: 15),
          ],

          ElevatedButton(
            onPressed: _handleUserSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              _isLoginMode ? "تسجيل الدخول" : "إنشاء حساب",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),

          const SizedBox(height: 20),

          // Toggle Login/Register
          TextButton(
            onPressed: () {
              setState(() {
                _isLoginMode = !_isLoginMode;
              });
            },
            child: Text(
              _isLoginMode
                  ? "ليس لديك حساب؟ إنشاء حساب جديد"
                  : "لديك حساب بالفعل؟ تسجيل الدخول",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      textAlign: TextAlign.right,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'الرجاء إدخال $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
