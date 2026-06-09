import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _keyBalance = 'current_balance';
  static const String _keyTotalPemasukan = 'total_pemasukan';
  static const String _keyTotalPengeluaran = 'total_pengeluaran';
  static const String _keyTransactions = 'transactions';
  static const String _keyMissions = 'missions';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Map<String, dynamic> defaultData() {
    return {
      'balance': 0.0,
      'totalPemasukan': 0.0,
      'totalPengeluaran': 0.0,
      'transactions': <Map<String, dynamic>>[],
      'missions': <Map<String, dynamic>>[],
    };
  }

  static Future<void> saveAllData({
    required double balance,
    required double totalPemasukan,
    required double totalPengeluaran,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> missions,
  }) async {
    try {
      final prefs = await _getPrefs();

      await prefs.setDouble(_keyBalance, balance);
      await prefs.setDouble(_keyTotalPemasukan, totalPemasukan);
      await prefs.setDouble(_keyTotalPengeluaran, totalPengeluaran);
      await prefs.setString(_keyTransactions, jsonEncode(transactions));
      await prefs.setString(_keyMissions, jsonEncode(missions));
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  static Future<Map<String, dynamic>> loadAllData() async {
    try {
      final prefs = await _getPrefs();

      final balance = prefs.getDouble(_keyBalance) ?? 1500000;
      final totalPemasukan = prefs.getDouble(_keyTotalPemasukan) ?? 1500000;
      final totalPengeluaran = prefs.getDouble(_keyTotalPengeluaran) ?? 0;

      final transactions = _loadTransactions(prefs);
      final missions = _loadMissions(prefs);

      return {
        'balance': balance,
        'totalPemasukan': totalPemasukan,
        'totalPengeluaran': totalPengeluaran,
        'transactions': transactions,
        'missions': missions,
      };
    } catch (e) {
      debugPrint('Error loading data: $e');
      return {
        'balance': 1500000.0,
        'totalPemasukan': 1500000.0,
        'totalPengeluaran': 0.0,
        'transactions': <Map<String, dynamic>>[],
        'missions': <Map<String, dynamic>>[],
      };
    }
  }

  static List<Map<String, dynamic>> _loadTransactions(SharedPreferences prefs) {
    final String? transactionsJson = prefs.getString(_keyTransactions);
    if (transactionsJson == null || transactionsJson.isEmpty) {
      return [];
    }
    try {
      List<dynamic> decoded = jsonDecode(transactionsJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error parsing transactions: $e');
      return [];
    }
  }

  static List<Map<String, dynamic>> _loadMissions(SharedPreferences prefs) {
    final String? missionsJson = prefs.getString(_keyMissions);
    if (missionsJson == null || missionsJson.isEmpty) {
      return [
        {
          'id': 1,
          'title': 'Hemat Makan di Luar',
          'target': 500000,
          'current': 0,
          'deadline': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'reward': 50,
        },
        {
          'id': 2,
          'title': 'Batasi Belanja Online',
          'target': 300000,
          'current': 0,
          'deadline': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
          'reward': 30,
        },
      ];
    }
    try {
      List<dynamic> decoded = jsonDecode(missionsJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error parsing missions: $e');
      return [];
    }
  }

  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyTransactions, jsonEncode(transactions));
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  static Future<void> saveMissions(List<Map<String, dynamic>> missions) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyMissions, jsonEncode(missions));
    } catch (e) {
      debugPrint('Error saving missions: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await _getPrefs();
      await prefs.clear();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}