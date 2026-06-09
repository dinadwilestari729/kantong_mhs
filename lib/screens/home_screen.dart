import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import 'add_transaction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _selectedIndex = 0;
  
  String _userName = '';
  
  double _currentBalance = 0;
  double _totalPemasukan = 0;
  double _totalPengeluaran = 0;
  List<Map<String, dynamic>> _transactions = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AuthService.getCurrentUser(),
        StorageService.loadAllData(),
      ]).timeout(
        const Duration(seconds: 8),
        onTimeout: () => [null, StorageService.defaultData()],
      );

      final currentUser = results[0]; // Map<String, dynamic>? — sudah inferred
      final data = results[1] ?? StorageService.defaultData(); // fallback jika null

      if (!mounted) return;
      setState(() {
        if (currentUser != null) {
          _userName = currentUser['name']?.toString() ?? '';
        }
        _currentBalance = (data['balance'] as num?)?.toDouble() ?? 0;
        _totalPemasukan = (data['totalPemasukan'] as num?)?.toDouble() ?? 0;
        _totalPengeluaran = (data['totalPengeluaran'] as num?)?.toDouble() ?? 0;
        final rawList = data['transactions'];
        _transactions = rawList is List
            ? rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('_loadData error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    await StorageService.saveAllData(
      balance: _currentBalance,
      totalPemasukan: _totalPemasukan,
      totalPengeluaran: _totalPengeluaran,
      transactions: _transactions,
      missions: [],
    );
  }

  Future<void> _addTransaction(double amount, String description, String type) async {
    setState(() {
      final newTransaction = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'amount': amount,
        'description': description,
        'date': DateTime.now().toIso8601String(),
        'type': type,
      };
      _transactions.insert(0, newTransaction);
      
      if (type == 'pemasukan') {
        _currentBalance += amount;
        _totalPemasukan += amount;
      } else {
        _currentBalance -= amount;
        _totalPengeluaran += amount;
      }
    });

    await _saveData();

    if (type == 'pengeluaran') {
      await _updateMissionProgress(description, amount);
    }
  }

  Future<void> _updateMissionProgress(String description, double amount) async {
    final data = await StorageService.loadAllData();
    List<Map<String, dynamic>> missions = List<Map<String, dynamic>>.from(data['missions']);
    
    bool missionUpdated = false;
    
    for (int i = 0; i < missions.length; i++) {
      final mission = missions[i];
      
      if (mission['current'] < mission['target']) {
        String missionTitle = mission['title'].toLowerCase();
        String descLower = description.toLowerCase();
        
        bool isRelevant = false;
        if (missionTitle.contains('makan') && (descLower.contains('makan') || descLower.contains('resto'))) {
          isRelevant = true;
        } else if (missionTitle.contains('belanja') && (descLower.contains('belanja') || descLower.contains('shop'))) {
          isRelevant = true;
        } else if (missionTitle.contains('transport') && (descLower.contains('transport') || descLower.contains('gojek') || descLower.contains('grab'))) {
          isRelevant = true;
        } else if (missionTitle.contains('hiburan') && (descLower.contains('nonton') || descLower.contains('game'))) {
          isRelevant = true;
        }
        
        if (isRelevant || missionTitle.contains('hemat')) {
          double newCurrent = mission['current'] + amount;
          missions[i]['current'] = newCurrent > mission['target'] ? mission['target'] : newCurrent;
          missionUpdated = true;
          
          if (newCurrent >= mission['target']) {
            _showMissionCompleteDialog(mission['title'], mission['reward']);
          }
        }
      }
    }
    
    if (missionUpdated) {
      await StorageService.saveMissions(missions);
      if (_selectedIndex == 1) {
        setState(() {});
      }
    }
  }

  void _showMissionCompleteDialog(String missionTitle, int reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Selamat!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 50, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Misi "$missionTitle" selesai!'),
            const SizedBox(height: 8),
            Text('Anda mendapat $reward poin!', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text('Memuat data...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _buildHomeContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                currentBalance: _currentBalance,
              ),
            ),
          );
          
          if (result != null && result is Map<String, dynamic>) {
            await _addTransaction(
              result['amount'],
              result['description'],
              result['type'],
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Transaksi'),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KantongMhs'),
            Text(
              'Halo, $_userName',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
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
                  const Text(
                    'Saldo Anda',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(_currentBalance),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
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
                      amount: _totalPemasukan,
                      color: Colors.green,
                      icon: Icons.arrow_downward,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Pengeluaran',
                      amount: _totalPengeluaran,
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
                  const Text(
                    '📋 Riwayat Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
            ),
          ),
          
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _transactions.length) {
                  return const SizedBox.shrink();
                }
                final transaction = _transactions[index];
                return _buildTransactionItem(transaction);
              },
              childCount: _transactions.length > 5 ? 5 : _transactions.length,
            ),
          ),
          
          if (_transactions.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Belum ada transaksi'),
                ),
              ),
            ),
          
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
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

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isPemasukan = transaction['type'] == 'pemasukan';
    final date = DateTime.parse(transaction['date']);
    
    return Card(
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
        title: Text(transaction['description']),
        subtitle: Text('${date.day}/${date.month}/${date.year}'),
        trailing: Text(
          _formatCurrency(transaction['amount']),
          style: TextStyle(
            color: isPemasukan ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}