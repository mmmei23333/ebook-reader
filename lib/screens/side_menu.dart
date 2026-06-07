import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      color: const Color(0xFFF5F5F5),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildHeader(context),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuCard(context, [
                    _MenuItem(Icons.workspace_premium, '专业版', () {
                      Navigator.pushNamed(context, '/upgrade_pro');
                    }),
                  ]),
                  const SizedBox(height: 8),
                  _buildMenuCard(context, [
                    _MenuItem(Icons.settings, '设置', () {
                      Navigator.pushNamed(context, '/settings');
                    }),
                    _MenuItem(Icons.brush, '外观', () {
                      Navigator.pushNamed(context, '/appearance');
                    }),
                    _MenuItem(Icons.list, '菜单', () {
                      Navigator.pushNamed(context, '/menu_management');
                    }),
                  ]),
                  const SizedBox(height: 8),
                  _buildMenuCard(context, [
                    _MenuItem(Icons.bar_chart, '统计', () {
                      Navigator.pushNamed(context, '/stats');
                    }),
                    _MenuItem(Icons.backup, '数据备份', () {
                      Navigator.pushNamed(context, '/backup');
                    }),
                    _MenuItem(Icons.cloud, '网盘和连接', () {
                      Navigator.pushNamed(context, '/cloud_connections');
                    }),
                    _MenuItem(Icons.description, 'TXT分章规则', () {
                      Navigator.pushNamed(context, '/txt_rules');
                    }),
                    _MenuItem(Icons.lock, '隐私安全', () {
                      Navigator.pushNamed(context, '/privacy_security');
                    }),
                  ]),
                  const SizedBox(height: 8),
                  _buildMenuCard(context, [
                    _MenuItem(Icons.help_outline, '使用指南', () {
                      Navigator.pushNamed(context, '/user_guide');
                    }),
                    _MenuItem(Icons.send, '建议反馈', () {
                      Navigator.pushNamed(context, '/feedback');
                    }),
                    _MenuItem(Icons.thumb_up, '好评鼓励', () {}),
                    _MenuItem(Icons.apps, '我的其他作品', () {}),
                    _MenuItem(Icons.info_outline, '关于', () {
                      Navigator.pushNamed(context, '/about');
                    }),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 32, color: Colors.grey[500]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '让阅读成为一种习惯',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: const Color(0xFF555555), size: 22),
                title: Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                ),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                onTap: item.onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                minLeadingWidth: 24,
              ),
              if (!isLast)
                Divider(height: 1, indent: 56, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'side_menu',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: const SideMenu(),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.title, this.onTap);
}
