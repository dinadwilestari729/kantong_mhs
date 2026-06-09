import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await StorageService.loadAllData();
      if (!mounted) return;
      setState(() {
        _transactions = List<Map<String, dynamic>>.from(data['transactions'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final type = transaction['type'];

    final data = await StorageService.loadAllData();
    double newBalance = (data['balance'] as num?)?.toDouble() ?? 0;
    double newTotalPemasukan = (data['totalPemasukan'] as num?)?.toDouble() ?? 0;
    double newTotalPengeluaran = (data['totalPengeluaran'] as num?)?.toDouble() ?? 0;

    if (type == 'pemasukan') {
      newBalance -= amount;
      newTotalPemasukan -= amount;
    } else {
      newBalance += amount;
      newTotalPengeluaran -= amount;
    }

    final updatedTransactions = _transactions.where((t) => t['id'] != transaction['id']).toList();

    await StorageService.saveAllData(
      balance: newBalance,
      totalPemasukan: newTotalPemasukan,
      totalPengeluaran: newTotalPengeluaran,
      transactions: updatedTransactions,
      missions: List<Map<String, dynamic>>.from(data['missions'] ?? []),
    );

    if (!mounted) return;

    setState(() {
      _transactions = updatedTransactions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaksi berhasil dihapus'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatCurrency(double amount) {
    try {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
      return formatter.format(amount);
    } catch (e) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isPemasukan = transaction['type'] == 'pemasukan';
    DateTime? date;
    try {
      date = DateTime.parse(transaction['transaction_date']);
    } catch (_) {
      date = DateTime.now();
    }

    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;

    return Dismissible(
      key: Key(transaction['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteTransaction(transaction);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isPemasukan
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            child: Icon(
              isPemasukan ? Icons.add : Icons.remove,
              color: isPemasukan ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction['description'] ?? 'Transaksi'),
          subtitle: Text('${date.day}/${date.month}/${date.year}'),
          trailing: Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: isPemasukan ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : _transactions.isEmpty
              ? const Center(
                  child: Text('Belum ada transaksi'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(_transactions[index]);
                  },
                ),
    );
  }
}
