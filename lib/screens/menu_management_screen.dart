import 'package:flutter/material.dart';

class MenuManagementScreen extends StatelessWidget {
  const MenuManagementScreen({super.key});

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
        title: const Text('菜单管理', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(context, '书库', [
            _buildMenuItem(Icons.folder, '书库', '管理您的电子书库'),
            _buildMenuItem(Icons.history, '最近阅读', '查看最近阅读的书籍'),
            _buildMenuItem(Icons.favorite, '收藏', '收藏的书籍'),
            _buildMenuItem(Icons.delete, '回收站', '已删除的书籍'),
          ]),
          const SizedBox(height: 16),
          _buildSection(context, '漫画', [
            _buildMenuItem(Icons.collections, '漫画库', '管理您的漫画'),
            _buildMenuItem(Icons.history, '最近阅读', '查看最近阅读的漫画'),
            _buildMenuItem(Icons.favorite, '收藏', '收藏的漫画'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(width: 4),
              Icon(Icons.edit, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF555555), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      trailing: const Icon(Icons.drag_handle, color: Color(0xFFCCCCCC), size: 20),
    );
  }
}
