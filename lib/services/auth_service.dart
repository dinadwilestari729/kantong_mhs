import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'storage_service.dart';

class AuthService {
  static const String _keyUsers = 'registered_users';
  static const String _keyCurrentUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static Future<SharedPreferences> _getPrefs() async {
    await StorageService.init();
    return await SharedPreferences.getInstance();
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String name) async {
    final prefs = await _getPrefs();

    try {
      String? usersJson = prefs.getString(_keyUsers);
      List<Map<String, dynamic>> users = [];

      if (usersJson != null && usersJson.isNotEmpty) {
        users = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      }

      for (var user in users) {
        if (user['email'] == email) {
          return {'success': false, 'message': 'Email sudah terdaftar'};
        }
      }

      users.add({
        'email': email,
        'password': password,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_keyUsers, jsonEncode(users));

      return {'success': true, 'message': 'Registrasi berhasil'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final prefs = await _getPrefs();

    try {
      String? usersJson = prefs.getString(_keyUsers);
      if (usersJson == null || usersJson.isEmpty) {
        return {'success': false, 'message': 'Belum ada user terdaftar'};
      }

      List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(jsonDecode(usersJson));

      for (var user in users) {
        if (user['email'] == email && user['password'] == password) {
          await prefs.setString(
              _keyCurrentUser,
              jsonEncode({
                'email': email,
                'name': user['name'],
                'login_at': DateTime.now().toIso8601String(),
              }));
          await prefs.setBool(_keyIsLoggedIn, true);

          await _initUserData(prefs, email);

          return {
            'success': true,
            'message': 'Login berhasil',
            'user': user['name']
          };
        }
      }

      return {'success': false, 'message': 'Email atau password salah'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  static Future<void> _initUserData(
      SharedPreferences prefs, String email) async {
    final hasData = prefs.containsKey('current_balance');
    if (!hasData) {
      await Future.wait([
        prefs.setDouble('current_balance', 1500000),
        prefs.setDouble('total_pemasukan', 1500000),
        prefs.setDouble('total_pengeluaran', 0),
        prefs.setString('transactions', jsonEncode([])),
        prefs.setString('missions', jsonEncode([])),
      ]);
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await _getPrefs();

    try {
      bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return null;

      String? userJson = prefs.getString(_keyCurrentUser);
      if (userJson == null || userJson.isEmpty) return null;

      return jsonDecode(userJson);
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyCurrentUser);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }
}