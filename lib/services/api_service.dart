import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.0.103/kantong_mhs_api';
  
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      print('📤 Register: name=$name, email=$email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📤 Login: email=$email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      print('📥 Response: ${response.body}');
      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('user_name', data['name']);
        await prefs.setString('user_email', data['email']);
        await prefs.setBool('is_logged_in', true);
        print('✅ Session saved: user_id=${data['user_id']}, name=${data['name']}');
      }
      
      return data;
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ Logout success, session cleared');
  }
  
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getInt('user_id'),
      'name': prefs.getString('user_name'),
      'email': prefs.getString('user_email'),
    };
  }
  
  static Future<Map<String, dynamic>> getTransactions(int userId) async {
    try {
      print('📤 Get transactions: userId=$userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/transactions/read.php?user_id=$userId'),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e', 'transactions': []};
    }
  }
  
  static Future<Map<String, dynamic>> addTransaction({
    required int userId,
    required double amount,
    required String description,
    required String type,
    required String date,
  }) async {
    try {
      print('📤 Add transaction: userId=$userId, amount=$amount, description=$description, type=$type, date=$date');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'amount': amount,
          'description': description,
          'type': type,
          'transaction_date': date,
        }),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> updateTransaction({
    required int id,
    required int userId,
    required double amount,
    required String description,
    required String type,
    required String date,
  }) async {
    try {
      print('📤 Update transaction: id=$id, userId=$userId, amount=$amount, description=$description, type=$type, date=$date');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/update.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'user_id': userId,
          'amount': amount,
          'description': description,
          'type': type,
          'transaction_date': date,
        }),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> deleteTransaction(int id, int userId) async {
    try {
      print('📤 Delete transaction: id=$id, userId=$userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/delete.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': id,
          'user_id': userId,
        }),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> getMissions(int userId) async {
    try {
      print('📤 Get missions: userId=$userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/missions/read.php?user_id=$userId'),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e', 'missions': []};
    }
  }
  
  static Future<Map<String, dynamic>> createMission({
    required int userId,
    required String title,
    required double targetAmount,
    int rewardPoints = 10,
    String? deadline,
  }) async {
    try {
      print('📤 Create mission: userId=$userId, title=$title, targetAmount=$targetAmount');
      
      final response = await http.post(
        Uri.parse('$baseUrl/missions/create.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'title': title,
          'target_amount': targetAmount,
          'reward_points': rewardPoints,
          'deadline': deadline,
        }),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> updateMissionProgress(int missionId) async {
    try {
      print('📤 Update mission progress: missionId=$missionId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/missions/update_progress.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mission_id': missionId,
        }),
      );
      
      print('📥 Response: ${response.body}');
      return json.decode(response.body);
    } catch (e) {
      print('❌ Error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}