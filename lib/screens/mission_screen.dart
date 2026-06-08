import 'package:flutter/material.dart';

class MissionScreen extends StatelessWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Misi Hemat"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.flag),
              title: Text("Hemat Makan di Luar"),
              subtitle: Text("Target Rp500.000"),
            ),
          ),
        ],
      ),
    );
  }
}