import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TransactionProvider with ChangeNotifier {
  List<Map<String, dynamic>> _transactions = [];
  double _balance = 0;
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get transactions => _transactions;
  double get balance => _balance;
  double get totalPemasukan => _totalPemasukan;
  double get totalPengeluaran => _totalPengeluaran;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions(int userId) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.getTransactions(userId);

    if (result['success'] == true) {
      _transactions = List<Map<String, dynamic>>.from(result['transactions']);
      _totalPemasukan = double.tryParse(result['total_pemasukan'].toString()) ?? 0;
      _totalPengeluaran = double.tryParse(result['total_pengeluaran'].toString()) ?? 0;
      _balance = double.tryParse(result['balance'].toString()) ?? 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTransaction({
    required int userId,
    required double amount,
    required String description,
    required String type,
    required String date,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.addTransaction(
      userId: userId,
      amount: amount,
      description: description,
      type: type,
      date: date,
    );

    _isLoading = false;
    notifyListeners();

    if (result['success'] == true) {
      await loadTransactions(userId);
      return true;
    }
    return false;
  }

  Future<bool> deleteTransaction(int id, int userId) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.deleteTransaction(id, userId);

    _isLoading = false;
    notifyListeners();

    if (result['success'] == true) {
      await loadTransactions(userId);
      return true;
    }
    return false;
  }
}