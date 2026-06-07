import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoContinue = true;
  bool _hapticFeedback = true;
  bool _hideHomeIndicator = false;
  bool _hideProAfterPurchase = false;
  bool _customLayout = false;
  bool _ignoreFontSize = false;

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
        title: const Text('设置', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard([
            _buildNavRow('语言', '简体中文'),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('新漫画包设置'),
            _buildNavRow('预设', '默认'),
            _buildNavRow('阅读方向', '从左到右'),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('epub/mobi/azw设置'),
            _buildToggleRow('自定义排版', _customLayout, (v) => setState(() => _customLayout = v)),
            _buildToggleRow('忽略字体大小', _ignoreFontSize, (v) => setState(() => _ignoreFontSize = v)),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('首页设置'),
            _buildToggleRow('启动时自动继续上次阅读', _autoContinue, (v) => setState(() => _autoContinue = v)),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildToggleRow('震动反馈', _hapticFeedback, (v) => setState(() => _hapticFeedback = v)),
            _buildToggleRow('自动隐藏Home Indicator', _hideHomeIndicator, (v) => setState(() => _hideHomeIndicator = v)),
            _buildToggleRow('购买后隐藏专业版入口', _hideProAfterPurchase, (v) => setState(() => _hideProAfterPurchase = v)),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildNavRow('数据库修复', null),
            _buildNavRow('缓存管理', null),
          ]),
        ],
      ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ),
    );
  }

  Widget _buildNavRow(String title, String? subtitle) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
