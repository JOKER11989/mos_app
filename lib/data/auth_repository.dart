import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'bids_repository.dart';
import 'notifications_repository.dart';
import 'purchases_repository.dart';

class AuthRepository extends ChangeNotifier {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final _supabase = Supabase.instance.client;

  User? _currentUser;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isBlocked => _currentUser?.isBlocked ?? false;

  String _normalizePhone(String phone) {
    String p = phone.trim();
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    for (int i = 0; i < 10; i++) {
      p = p.replaceAll(arabic[i], i.toString());
    }
    p = p.replaceAll(RegExp(r'[^0-9]'), '');

    if (p.startsWith('07')) {
      p = p.substring(1);
    }
    if (p.startsWith('964')) {
      p = p.substring(3);
    }

    return p;
  }

  String? _verificationId;

  // Step 1: Request SMS Code (BYPASS MODE ONLY FOR NOW)
  Future<void> verifyPhone({
    required String phone,
    required Function(String) onCodeSent,
    required Function(String) onError,
    Function(String)? onCodeAutoRetrieval,
  }) async {
    try {
      debugPrint('Starting Bypass Phone Auth for: $phone');
      // BYPASS LOGIC: Immediately return a dummy verification ID
      _verificationId = "bypass_verification_id";
      onCodeSent(_verificationId!);
    } catch (e) {
      debugPrint('Verify Phone Error: $e');
      onError('حدث خطأ غير متوقع: $e');
    }
  }

  // Step 2: Submit OTP and Login/Register
  Future<User> submitOTP({
    required String smsCode,
    required bool isRegister,
    String? phone,
    String? name,
    String? address,
    String? region,
    String? nearestPoint,
  }) async {
    if (_verificationId == null) {
      throw Exception('لم يتم طلب الكود بعد');
    }

    try {
      if (smsCode != "123456") {
        throw Exception("كود التحقق غير صحيح (استخدم 123456 للتجربة)");
      }

      if (phone == null) throw Exception("رقم الهاتف مطلوب");

      final phoneDigits = _normalizePhone(phone);
      final uid = DateTime.now().millisecondsSinceEpoch
          .toString(); // Generate ID

      // Check if user exists in Supabase 'users' table
      final data = await _supabase
          .from('users')
          .select()
          .eq('phone', phoneDigits)
          .maybeSingle();

      if (data != null) {
        // User exists
        final existingUser = User.fromJson(data);

        if (existingUser.isBlocked) {
          throw Exception("حسابك محظور");
        }

        // Update local state
        _currentUser = existingUser;

        // Force Admin Check (Legacy logic)
        const String bossPhone = "07711131188";
        if (phoneDigits == bossPhone || phoneDigits == "9647711131188") {
          if (!_currentUser!.isAdmin) {
            _currentUser = _currentUser!.copyWith(isAdmin: true);
            await updateUser(_currentUser!);
          }
        }
      } else {
        // User NOT in DB
        if (!isRegister) {
          throw Exception("رقم الهاتف غير مسجل. الرجاء إنشاء حساب جديد.");
        }

        // Create new user
        final newUser = User(
          id: uid, // Use timestamp ID for bypass
          name: name ?? 'مستخدم جديد',
          phone: phoneDigits,
          address: address,
          region: region,
          nearestPoint: nearestPoint,
          isAdmin: false,
        );

        // Insert into Supabase
        await _supabase.from('users').insert(newUser.toJson());
        _currentUser = newUser;
      }

      NotificationsRepository().clearAll();
      await _saveUserToPrefs(_currentUser!);
      notifyListeners();
      return _currentUser!;
    } catch (e) {
      debugPrint('Submit OTP Error: $e');
      rethrow;
    }
  }

  Future<void> initializeDefaultAdmin() async {
    if (_isInitialized) return;
    await _loadUserFromPrefs();
    _isInitialized = true;
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
  }

  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('cached_user');
      if (userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));

        // Try to refresh from Supabase if online
        try {
          final data = await _supabase
              .from('users')
              .select()
              .eq('id', _currentUser!.id)
              .maybeSingle();
          if (data != null) {
            _currentUser = User.fromJson(data);
            await _saveUserToPrefs(_currentUser!);
          }
        } catch (_) {}

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
    }
  }

  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user');
    } catch (e) {
      debugPrint('Error clearing user from prefs: $e');
    }
  }

  Future<void> waitForAuthInitialization() async {
    // Just wait a bit for prefs to load
    await Future.delayed(const Duration(milliseconds: 200));
  }

  Future<void> updateUser(User updatedUser) async {
    try {
      await _supabase
          .from('users')
          .update(updatedUser.toJson())
          .eq('id', updatedUser.id);

      _currentUser = updatedUser;
      await _saveUserToPrefs(updatedUser);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  Future<void> loginAdmin(String email, String password) async {
    // Simplified Admin Login for now
    String finalEmail = email.trim().replaceAll(' ', '');
    const String masterPassword = "joker1100";

    if (password == masterPassword) {
      // Fetch any admin
      final data = await _supabase
          .from('users')
          .select()
          .eq('isAdmin', true)
          .limit(1)
          .maybeSingle();

      if (data != null) {
        _currentUser = User.fromJson(data);
        await _saveUserToPrefs(_currentUser!);
        notifyListeners();
        return;
      } else {
        // Create Default Admin if none exists
        final adminUser = User(
          id: 'admin_1',
          name: 'Admin',
          phone: '000000',
          isAdmin: true,
        );
        _currentUser = adminUser;
        // Try to save to DB so it persists
        try {
          await _supabase.from('users').upsert(adminUser.toJson());
        } catch (e) {
          debugPrint("Could not sync default admin: $e");
        }

        await _saveUserToPrefs(_currentUser!);
        notifyListeners();
        return;
      }
    }
    throw Exception('كلمة المرور غير صحيحة');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Not supported in bypass mode
    throw Exception('غير مدعوم حالياً');
  }

  Future<User> loginUser({
    required String name,
    required String phone,
    String? address,
    String? region,
    String? nearestPoint,
  }) async {
    // Reuse submitOTP logic for register
    return submitOTP(
      smsCode: "123456",
      isRegister: true,
      phone: phone,
      name: name,
      address: address,
      region: region,
      nearestPoint: nearestPoint,
    );
  }

  Future<User> loginExistingUser({required String phone}) async {
    // Reuse submitOTP logic for login
    return submitOTP(smsCode: "123456", isRegister: false, phone: phone);
  }

  Future<void> logout() async {
    // _supabase.auth.signOut(); // Not using real auth yet
    _currentUser = null;
    await _clearUserFromPrefs();
    await BidsRepository().clearData();
    NotificationsRepository().clearAll();
    await PurchasesRepository().clearData();
    notifyListeners();
  }

  Stream<List<User>> getAllUsersStream() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => User.fromJson(json)).toList());
  }
}
