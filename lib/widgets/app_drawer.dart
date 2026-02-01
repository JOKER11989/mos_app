import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../data/settings_repository.dart';
import '../data/auth_repository.dart';
import '../screens/admin_screen.dart';
import '../screens/transactions_screen.dart';
import '../screens/contact_us_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';

class LanguageBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageBtn({
    super.key,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// --- 2. القائمة الجانبية (كما في الصورة الأولى) ---
// ==========================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          // رأس القائمة (معلومات المستخدم)
          ListenableBuilder(
            listenable: AuthRepository(),
            builder: (context, child) {
              final user = AuthRepository().currentUser;
              final name = user?.name ?? "Guest";
              final region = user?.region ?? user?.address ?? "";

              final imagePath = user?.imagePath;

              return InkWell(
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  color: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.only(
                    top: 50,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: ClipOval(
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: imagePath != null
                                ? (kIsWeb
                                      ? Image.network(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Text(
                                                    name.isNotEmpty
                                                        ? name[0].toUpperCase()
                                                        : "?",
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                        )
                                      : Image.file(
                                          File(imagePath),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Center(
                                                  child: Text(
                                                    name.isNotEmpty
                                                        ? name[0].toUpperCase()
                                                        : "?",
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              },
                                        ))
                                : Center(
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : "?",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.edit,
                                  color: Colors.grey,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "\$0.0${region.isNotEmpty ? '   |   $region' : ''}",
                              style: const TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 12,
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
            },
          ),

          // جعل القائمة قابلة للتمرير لضمان ظهور جميع العناصر
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 10),

                // Navigation Items
                ListTile(
                  leading: const Icon(Icons.home_outlined, color: Colors.grey),
                  title: const Text(
                    "الصفحة الرئيسية",
                    textAlign: TextAlign.right,
                  ),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    // Already on home/navigation screen usually
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.grey),
                  title: const Text("المعاملات", textAlign: TextAlign.right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    );
                  },
                ),
                if (AuthRepository().isAdmin)
                  ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.grey,
                    ),
                    title: const Text(
                      "لوحة التحكم",
                      textAlign: TextAlign.right,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminScreen()),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.phone_in_talk_outlined,
                    color: Colors.grey,
                  ),
                  title: const Text("تحدث معنا", textAlign: TextAlign.right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactUsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text("عننا", textAlign: TextAlign.right),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutUsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Colors.grey),
                  title: const Text(
                    "Share this App",
                    textAlign: TextAlign.right,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(
                      'Check out this amazing Auction App! Download now.',
                    );
                  },
                ),

                const Divider(color: Colors.grey, thickness: 0.5),

                // زر تبديل الوضع الليلي
                ListenableBuilder(
                  listenable: SettingsRepository(),
                  builder: (context, child) {
                    final isDark =
                        SettingsRepository().themeMode == ThemeMode.dark;
                    return SwitchListTile(
                      activeThumbColor: Colors.blueAccent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: const Text(
                        "Dark Mode",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      secondary: const Icon(
                        Icons.nightlight_round,
                        color: Colors.blueAccent,
                      ),
                      value: isDark,
                      onChanged: (v) {
                        SettingsRepository().toggleTheme(v);
                      },
                    );
                  },
                ),

                // أزرار اختيار اللغة
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListenableBuilder(
                    listenable: SettingsRepository(),
                    builder: (context, child) {
                      final currentLang =
                          SettingsRepository().locale.languageCode;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          LanguageBtn(
                            label: 'عربي',
                            isSelected: currentLang == 'ar',
                            onTap: () => SettingsRepository().setLanguage('ar'),
                          ),
                          LanguageBtn(
                            label: 'كوردى',
                            isSelected: currentLang == 'ku',
                            onTap: () => SettingsRepository().setLanguage('ku'),
                          ),
                          LanguageBtn(
                            label: 'English',
                            isSelected: currentLang == 'en',
                            onTap: () => SettingsRepository().setLanguage('en'),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                // زر تسجيل الخروج
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C1E1E),
                      foregroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                    ),
                    onPressed: () async {
                      await AuthRepository().logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
