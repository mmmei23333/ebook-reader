import 'package:flutter/material.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  int _appearanceMode = 0; // 0=跟随系统, 1=浅色, 2=深色
  int _navigationMode = 0;
  int _selectedThemeIndex = 0;
  bool _bookSpineEffect = true;
  bool _openAnimation = true;
  bool _showReadingTime = false;
  bool _showProgress = true;

  final List<_ThemeColor> _themes = [
    _ThemeColor('默认', const Color(0xFF2196F3)),
    _ThemeColor('活力橙', const Color(0xFFFF9800)),
    _ThemeColor('金盏黄', const Color(0xFFFFC107)),
    _ThemeColor('电光蓝', const Color(0xFF03A9F4)),
    _ThemeColor('深海蓝', const Color(0xFF1565C0)),
    _ThemeColor('魅惑紫', const Color(0xFF9C27B0)),
    _ThemeColor('赛博紫', const Color(0xFF7B1FA2)),
    _ThemeColor('极光青', const Color(0xFF00BCD4)),
    _ThemeColor('樱花粉', const Color(0xFFE91E63)),
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
        title: const Text('外观', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard([
            _buildSectionTitle('外观模式'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildChip('跟随系统', 0),
                  const SizedBox(width: 8),
                  _buildChip('浅色', 1),
                  const SizedBox(width: 8),
                  _buildChip('深色', 2),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('导航模式'),
            ListTile(
              title: const Text('经典侧滑模式', style: TextStyle(fontSize: 15)),
              trailing: Icon(_navigationMode == 0 ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _navigationMode == 0 ? Theme.of(context).colorScheme.primary : Colors.grey[300]),
              onTap: () => setState(() => _navigationMode = 0),
            ),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('主题色'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _themes.length,
                itemBuilder: (ctx, i) => _buildThemeItem(i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildManageBtn('添加'),
                  _buildManageBtn('修改'),
                  _buildManageBtn('导入'),
                  _buildManageBtn('分享'),
                  _buildManageBtn('删除'),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('界面字体'),
            ListTile(
              title: const Text('字体', style: TextStyle(fontSize: 15)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('默认', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _buildCard([
            _buildSectionTitle('书架'),
            _buildToggleRow('书脊效果', _bookSpineEffect, (v) => setState(() => _bookSpineEffect = v)),
            _buildToggleRow('打开动画', _openAnimation, (v) => setState(() => _openAnimation = v)),
            _buildToggleRow('显示阅读时长', _showReadingTime, (v) => setState(() => _showReadingTime = v)),
            _buildToggleRow('显示阅读进度', _showProgress, (v) => setState(() => _showProgress = v)),
          ]),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    final selected = _appearanceMode == index;
    return GestureDetector(
      onTap: () => setState(() => _appearanceMode = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 14,
          color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFF666666),
        )),
      ),
    );
  }

  Widget _buildThemeItem(int index) {
    final theme = _themes[index];
    final selected = _selectedThemeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedThemeIndex = index),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.color,
              shape: BoxShape.circle,
              border: selected ? Border.all(color: const Color(0xFF333333), width: 2.5) : null,
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
          const SizedBox(height: 4),
          Text(theme.name, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildManageBtn(String label) {
    return TextButton(
      onPressed: () {},
      child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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

class _ThemeColor {
  final String name;
  final Color color;
  _ThemeColor(this.name, this.color);
}
