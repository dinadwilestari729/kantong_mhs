import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  List<Map<String, dynamic>> _missions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() {
      _isLoading = true;
    });
    
    final data = await StorageService.loadAllData();
    
    setState(() {
      _missions = List<Map<String, dynamic>>.from(data['missions']);
      _isLoading = false;
    });
  }

  Future<void> _saveMissions() async {
    await StorageService.saveMissions(_missions);
  }

  Future<void> _addMission(String title, double target, int days, int reward) async {
    setState(() {
      _missions.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': title,
        'target': target,
        'current': 0,
        'deadline': DateTime.now().add(Duration(days: days)).toIso8601String(),
        'reward': reward,
      });
    });
    await _saveMissions();
  }

  Future<void> _claimReward(int index) async {
    final reward = _missions[index]['reward'];
    
    setState(() {
      _missions.removeAt(index);
    });
    await _saveMissions();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Selamat! Anda mendapat $reward poin!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showAddMissionDialog() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final daysController = TextEditingController();
    final rewardController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Misi Hemat Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Misi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Penghematan (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durasi (hari)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rewardController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poin Reward',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  targetController.text.isNotEmpty &&
                  daysController.text.isNotEmpty &&
                  rewardController.text.isNotEmpty) {
                final nav = Navigator.of(context);
                await _addMission(
                  titleController.text,
                  double.parse(targetController.text),
                  int.parse(daysController.text),
                  int.parse(rewardController.text),
                );
                nav.pop();
              }
            },
            child: const Text('Simpan'),
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
              Text('Memuat misi...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Misi Hemat'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _missions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada misi hemat'),
                  SizedBox(height: 8),
                  Text('Tekan tombol + untuk membuat misi'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _missions.length,
              itemBuilder: (context, index) {
                final mission = _missions[index];
                final current = (mission['current'] as num).toDouble();
                final target = (mission['target'] as num).toDouble();
                final progress = current / target;
                final deadline = DateTime.parse(mission['deadline']);
                final remainingDays = deadline.difference(DateTime.now()).inDays;
                final isCompleted = progress >= 1;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                mission['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${mission['reward']} poin',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: isCompleted ? Colors.green : Colors.orange,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatCurrency(current),
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              _formatCurrency(target),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: remainingDays < 0 ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              remainingDays < 0
                                  ? 'Melebihi tenggat'
                                  : 'Sisa $remainingDays hari',
                              style: TextStyle(
                                fontSize: 12,
                                color: remainingDays < 0 ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Text(
                          'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        
                        if (isCompleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton(
                              onPressed: () => _claimReward(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: const Text('Klaim Hadiah'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMissionDialog,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}