import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  Future<void> _deleteTransaction(BuildContext context, Map<String, dynamic> transaction) async {
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    
    final success = await transactionProvider.deleteTransaction(
      transaction['id'],
      authProvider.userId,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    try {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
      return formatter.format(amount);
    } catch (e) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> transaction) {
    final isPemasukan = transaction['type'] == 'pemasukan';
    DateTime? date;
    try {
      date = DateTime.parse(transaction['transaction_date']);
    } catch (_) {
      date = DateTime.now();
    }

    final amount = double.tryParse(transaction['amount'].toString()) ?? 0;

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
        _deleteTransaction(context, transaction);
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
    final transactionProvider = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Transaksi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: transactionProvider.isLoading && transactionProvider.transactions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            )
          : transactionProvider.transactions.isEmpty
              ? const Center(
                  child: Text('Belum ada transaksi'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: transactionProvider.transactions.length,
                  itemBuilder: (context, index) {
                    return _buildTransactionItem(context, transactionProvider.transactions[index]);
                  },
                ),
    );
  }
}
