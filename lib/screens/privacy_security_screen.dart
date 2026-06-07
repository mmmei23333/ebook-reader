import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _faceId = false;
  bool _appLock = false;
  bool _showHiddenBooks = false;

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
        title: const Text('隐私安全', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.gesture, color: Theme.of(context).colorScheme.primary, size: 22),
              title: const Text('设置手势密码', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.face, color: Theme.of(context).colorScheme.primary, size: 22),
                  title: const Text('启用Face ID', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                  value: _faceId,
                  onChanged: (v) => setState(() => _faceId = v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                SwitchListTile(
                  secondary: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary, size: 22),
                  title: const Text('应用锁', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                  subtitle: Text('启动应用时需要验证身份', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                  value: _appLock,
                  onChanged: (v) => setState(() => _appLock = v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
                SwitchListTile(
                  secondary: Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary, size: 22),
                  title: const Text('查看隐藏书籍', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                  value: _showHiddenBooks,
                  onChanged: (v) => setState(() => _showHiddenBooks = v),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
