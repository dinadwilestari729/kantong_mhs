import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.userName);
    final emailController = TextEditingController(text: authProvider.userEmail);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              await authProvider.updateUserData(nameController.text, emailController.text);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diupdate')),
                );
              }
              nav.pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context, AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout? Data akan tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.logout();
      await StorageService.clearAllData();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              authProvider.userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              authProvider.userEmail,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit, color: Colors.green),
                    title: const Text('Edit Profil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showEditProfileDialog(context, authProvider),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.blue),
                    title: const Text('Tentang Aplikasi'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDialog(
                      context,
                      'Tentang KantongMhs',
                      'Aplikasi pencatatan keuangan untuk mahasiswa\n\nFitur:\n• Catat pemasukan/pengeluaran\n• Misi hemat dengan reward poin\n• Laporan keuangan\n• Data tersimpan otomatis',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: Colors.orange),
                    title: const Text('Bantuan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDialog(
                      context,
                      'Bantuan',
                      '1. Tambah transaksi dengan tombol +\n2. Buat misi hemat di menu Misi\n3. Pantau progress misi Anda\n4. Data otomatis tersimpan',
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () => _logout(context, authProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'KantongMhs v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}