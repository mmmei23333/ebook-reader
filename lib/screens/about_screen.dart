import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
        title: const Text('关于', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.menu_book, size: 40, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 14),
                const Text('阅读器', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 4),
                Text('版本 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 4),
                Text('Build 2026.06.07', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildLinkItem(Icons.star, '给我们评分', context),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                _buildLinkItem(Icons.language, '官方网站', context),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                _buildLinkItem(Icons.description, '用户协议', context),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                _buildLinkItem(Icons.privacy_tip, '隐私政策', context),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                _buildLinkItem(Icons.code, '开源许可', context),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildLinkItem(Icons.update, '检查更新', context),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                _buildLinkItem(Icons.mail, '联系我们', context),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('© 2026 阅读器团队', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
      onTap: () {},
    );
  }
}
