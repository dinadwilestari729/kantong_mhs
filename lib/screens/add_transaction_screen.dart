import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {

  final nominalController = TextEditingController();
  final deskripsiController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Transaksi"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nominalController,
              decoration: const InputDecoration(
                labelText: "Nominal",
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: deskripsiController,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}