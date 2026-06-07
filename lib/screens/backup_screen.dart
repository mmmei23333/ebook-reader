import 'package:flutter/material.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _autoBackup = false;

  final List<_BackupEntry> _history = [
    _BackupEntry('2026-06-07 10:30', '12.5 MB'),
    _BackupEntry('2026-06-06 22:15', '12.3 MB'),
    _BackupEntry('2026-06-05 09:00', '11.8 MB'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('数据备份', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Text(
              '数据备份可以保存您的阅读进度、书签、笔记等数据。建议定期备份以防数据丢失。',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('自动备份', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
              subtitle: Text('每日自动备份数据', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              value: _autoBackup,
              onChanged: (v) => setState(() => _autoBackup = v),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('立即备份', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
          Text('备份历史', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _history.map((entry) {
                return ListTile(
                  leading: Icon(Icons.description, color: Colors.grey[400]),
                  title: Text(entry.timestamp, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                  trailing: Text(entry.size, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  onTap: () {},
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text('管理旧版本数据', style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupEntry {
  final String timestamp;
  final String size;
  _BackupEntry(this.timestamp, this.size);
}
