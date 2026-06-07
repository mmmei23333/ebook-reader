import 'package:flutter/material.dart';

class CloudConnectionsScreen extends StatelessWidget {
  const CloudConnectionsScreen({super.key});

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
        title: const Text('网盘和连接', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard([
            _buildItem(Icons.wifi, 'WiFi传书', '在同一网络下传输书籍', context),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildItem(Icons.download, '我的下载', '查看已下载的文件', context),
          ]),
          const SizedBox(height: 12),
          _buildSectionTitle('添加连接'),
          _buildCard([
            _buildItem(Icons.web, 'WebDAV', '通过WebDAV协议连接', context),
            Divider(height: 1, indent: 56, color: Colors.grey[200]),
            _buildItem(Icons.computer, 'SMB', '通过SMB协议连接局域网共享', context),
            Divider(height: 1, indent: 56, color: Colors.grey[200]),
            _buildItem(Icons.rss_feed, 'OPDS', '通过OPDS目录连接', context),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('添加网盘'),
          _buildCard([
            _buildItem(Icons.cloud, '百度网盘', '连接百度网盘账号', context),
            Divider(height: 1, indent: 56, color: Colors.grey[200]),
            _buildItem(Icons.cloud_queue, '阿里云盘', '连接阿里云盘账号', context),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildItem(IconData icon, String title, String subtitle, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
      onTap: () {},
    );
  }
}
