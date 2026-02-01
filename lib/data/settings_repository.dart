import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository extends ChangeNotifier {
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('en');
  String _appTitle = 'Joker Store';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get appTitle => _appTitle;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    // Load theme
    // (Existing theme loading logic is likely handled elsewhere or defaulted)

    // Load title
    _appTitle = prefs.getString('appTitle') ?? 'Joker Store';
    notifyListeners();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(String languageCode) {
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setAppTitle(String newTitle) async {
    _appTitle = newTitle;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appTitle', newTitle);
    notifyListeners();
  }
}
