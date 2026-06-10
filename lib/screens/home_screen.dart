import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'mission_screen.dart';
import 'profile_screen.dart';
import 'transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    
    if (authProvider.userId > 0) {
      await transactionProvider.loadTransactions(authProvider.userId);
    }
  }

  Future<void> _addTransaction(double amount, String description, String type, DateTime date) async {
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    
    final success = await transactionProvider.addTransaction(
      userId: authProvider.userId,
      amount: amount,
      description: description,
      type: type,
      date: date.toIso8601String().split('T')[0],
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menambah transaksi'),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final transactionProvider = context.watch<TransactionProvider>();

    // Removed the full screen loading interceptor so it doesn't block the UI during CRUD.

    return Scaffold(
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Misi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
                      currentBalance: transactionProvider.balance,
                    ),
                  ),
                );
                
                if (result != null && result is Map<String, dynamic>) {
                  await _addTransaction(
                    result['amount'],
                    result['description'],
                    result['type'],
                    result['date'],
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Transaksi'),
            )
          : null,
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const MissionScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final transactionProvider = context.watch<TransactionProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KantongMhs'),
            Text(
              'Halo, ${authProvider.userName}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Saldo Anda', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(transactionProvider.balance),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Pemasukan',
                        amount: transactionProvider.totalPemasukan,
                        color: Colors.green,
                        icon: Icons.arrow_downward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Pengeluaran',
                        amount: transactionProvider.totalPengeluaran,
                        color: Colors.red,
                        icon: Icons.arrow_upward,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📋 Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TransactionsScreen()),
                        );
                        _loadData();
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= transactionProvider.transactions.length) {
                    return const SizedBox.shrink();
                  }
                  final transaction = transactionProvider.transactions[index];
                  return _buildTransactionItem(transaction);
                },
                childCount: transactionProvider.transactions.length > 5 ? 5 : transactionProvider.transactions.length,
              ),
            ),
            if (transactionProvider.transactions.isEmpty)
              const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada transaksi'))),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    
    final success = await transactionProvider.deleteTransaction(
      transaction['id'],
      authProvider.userId,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: Colors.red,
        ),
      );
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
        _deleteTransaction(transaction);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isPemasukan ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
            child: Icon(isPemasukan ? Icons.add : Icons.remove, color: isPemasukan ? Colors.green : Colors.red),
          ),
          title: Text(transaction['description'] ?? 'Transaksi'),
          subtitle: Text('${date.day}/${date.month}/${date.year}'),
          trailing: Text(
            _formatCurrency(amount),
            style: TextStyle(color: isPemasukan ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}