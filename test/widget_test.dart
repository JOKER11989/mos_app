import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mos/main.dart';

// Mock HttpOverrides to allow Image.network to work in tests
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  setUpAll(() {
    // Disable HTTP requests
    HttpOverrides.global = null;
  });

  testWidgets('App start smoke test', (WidgetTester tester) async {
    // Bypass network image loading issues in tests by overriding HTTP
    HttpOverrides.global = TestHttpOverrides();

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Cleanup
    HttpOverrides.global = null;
  });
}
