import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  int _userId = 0;
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = false;
  bool _isLoggedIn = false;

  int get userId => _userId;
  String get userName => _userName;
  String get userEmail => _userEmail;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await ApiService.isLoggedIn();
    if (_isLoggedIn) {
      final userData = await ApiService.getCurrentUser();
      _userId = userData['user_id'] ?? 0;
      _userName = userData['name'] ?? 'Pengguna';
      _userEmail = userData['email'] ?? '';
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.login(email, password);

    if (result['success'] == true) {
      _userId = int.parse(result['user_id'].toString());
      _userName = result['name'];
      _userEmail = result['email'];
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.register(name, email, password);

    _isLoading = false;
    notifyListeners();

    return result['success'] == true;
  }

  Future<void> logout() async {
    await ApiService.logout();
    _userId = 0;
    _userName = '';
    _userEmail = '';
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> updateUserData(String name, String email) async {
    _userName = name;
    _userEmail = email;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    
    notifyListeners();
  }
}