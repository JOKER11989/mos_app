import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تحدث معنا"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.headset_mic, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 30),
            const Text(
              "تواصل معنا عبر القنوات التالية:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blueAccent),
              title: const Text("البريد الإلكتروني"),
              subtitle: const Text("support@example.com"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text("رقم الهاتف"),
              subtitle: const Text("+964 770 123 4567"),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.purple),
              title: const Text("واتساب"),
              subtitle: const Text("اضغط للمحادثة"),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
