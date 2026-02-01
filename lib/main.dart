import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'data/settings_repository.dart';
import 'data/auth_repository.dart';
import 'data/product_repository.dart';
import 'data/bids_repository.dart';
import 'data/notifications_repository.dart';
import 'data/purchases_repository.dart';
import 'data/favorites_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://yodtbpqcfnmkmjaosqwr.supabase.co',
    anonKey: 'sb_publishable_UZWVCFmJJHc2cJdX2KvnJg_MwlwqXUd',
  );

  runApp(const MyApp());
}

// الكلاس الأساسي للتطبيق
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsRepository(),
      builder: (context, child) {
        final settings = SettingsRepository();
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Auction App',
          themeMode: settings.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0D1117),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF161B22),
              elevation: 0,
            ),
          ),
          locale: settings.locale,
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
            Locale('ku'), // Kurdish (Sorani/Kurmanji - using 'ku' generic)
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}

// Splash screen to check for saved session
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Initialize auth repository and load session
    // Initialize repositories
    await AuthRepository().initializeDefaultAdmin();
    await ProductRepository().initialize();
    await BidsRepository().initialize();
    await NotificationsRepository().initialize();
    await PurchasesRepository().initialize();
    await FavoritesRepository().initialize();

    // Ensure Auth is fully initialized before checking session
    await AuthRepository().waitForAuthInitialization();

    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check if user is logged in
    if (AuthRepository().isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
