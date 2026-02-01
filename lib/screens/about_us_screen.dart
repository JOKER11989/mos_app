import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("عننا"), centerTitle: true),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 100, color: Colors.blueAccent),
            SizedBox(height: 30),
            Text(
              "تطبيق المزايدات الأول",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "نحن نوفر منصة آمنة وموثوقة لبيع وشراء المنتجات عن طريق المزايدة العلنية. نضمن حقوق البائع والمشتري مع توفير أفضل تجربة مستخدم.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            Text("الإصدار 1.1.1", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
