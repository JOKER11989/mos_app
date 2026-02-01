import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/global_refresh_indicator.dart';
import '../data/auth_repository.dart';
import '../models/user.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إدارة المستخدمين")),
      body: GlobalRefreshIndicator(
        onRefresh: () async {
          // Placeholder for refreshing users, AuthRepository might need a refresh method
          await Future.delayed(const Duration(seconds: 1));
        },
        child: StreamBuilder<List<User>>(
          stream: AuthRepository().getAllUsersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data ?? [];

            if (users.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.35),
                  const Center(child: Text("لا يوجد مستخدمين مسجلين حالياً")),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: user.isBlocked ? Colors.red : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Image
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: user.imagePath != null
                                  ? (user.imagePath!.startsWith('http') ||
                                            kIsWeb &&
                                                !user.imagePath!.startsWith('/')
                                        ? NetworkImage(user.imagePath!)
                                        : FileImage(File(user.imagePath!))
                                              as ImageProvider)
                                  : null,
                              child: user.imagePath == null
                                  ? const Icon(Icons.person, size: 30)
                                  : null,
                            ),
                            const SizedBox(width: 15),

                            // User Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text("الهاتف: ${user.phone}"),
                                  Text(
                                    "العنوان: ${user.address ?? 'غير محدد'}",
                                  ),
                                  if (user.region != null)
                                    Text("المنطقة: ${user.region}"),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "ID: ${user.deviceId ?? user.id}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (user.isBlocked)
                              const Text(
                                "المستخدم محظور",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                _toggleBlockUser(user);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: user.isBlocked
                                    ? Colors.green
                                    : Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(
                                user.isBlocked
                                    ? Icons.check_circle
                                    : Icons.block,
                              ),
                              label: Text(
                                user.isBlocked ? "رفع الحظر" : "حظر المستخدم",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _toggleBlockUser(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isBlocked ? "رفع الحظر" : "حظر المستخدم"),
        content: Text(
          user.isBlocked
              ? "هل أنت متأكد من رغبتك في رفع الحظر عن ${user.name}؟"
              : "هل أنت متأكد من رغبتك في حظر ${user.name}؟ لن يتمكن من تسجيل الدخول.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final updatedUser = user.copyWith(isBlocked: !user.isBlocked);
              await AuthRepository().updateUser(updatedUser);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      updatedUser.isBlocked
                          ? "تم حظر المستخدم بنجاح"
                          : "تم رفع الحظر بنجاح",
                    ),
                    backgroundColor: updatedUser.isBlocked
                        ? Colors.red
                        : Colors.green,
                  ),
                );
              }
            },
            child: Text(
              user.isBlocked ? "رفع الحظر" : "حظر",
              style: TextStyle(
                color: user.isBlocked ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
