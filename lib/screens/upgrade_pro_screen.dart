import 'package:flutter/material.dart';

class UpgradeProScreen extends StatefulWidget {
  const UpgradeProScreen({super.key});

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen> {
  int _selectedPlan = 1;

  final List<_Plan> _plans = [
    _Plan('连续包月', '\$0.99', '/月', Icons.calendar_today),
    _Plan('连续包年', '\$5.99', '/年', Icons.date_range),
    _Plan('专业版买断', '\$12.99', '永久', Icons.all_inclusive),
  ];

  final List<_Feature> _features = [
    _Feature(Icons.palette, '自定义主题', '创建专属个性化主题'),
    _Feature(Icons.cloud_sync, '云同步', '多设备数据实时同步'),
    _Feature(Icons.speed, '高级排版', '更多排版选项和字体'),
    _Feature(Icons.lock, '应用锁', '保护您的隐私阅读'),
    _Feature(Icons.picture_as_pdf, 'PDF增强', '更强大的PDF阅读体验'),
    _Feature(Icons.translate, '翻译功能', '内置智能翻译助手'),
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
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('恢复购买', style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.workspace_premium, size: 48, color: Colors.amber[700]),
                const SizedBox(height: 12),
                const Text('升级专业版', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 6),
                Text('解锁全部高级功能', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(_plans.length, (i) {
            final plan = _plans[i];
            final selected = _selectedPlan == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: selected ? [BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )] : null,
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(plan.icon, color: Theme.of(context).colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                          const SizedBox(height: 2),
                          Text('自动续订，可随时取消', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                    Text(plan.price, style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )),
                    Text(plan.period, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                    const SizedBox(width: 8),
                    Icon(
                      selected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[300],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('专业版特权', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 12),
                ..._features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Icon(f.icon, color: Theme.of(context).colorScheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                            Text(f.desc, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('立即解锁', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '订阅可随时在设置中取消',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Plan {
  final String title;
  final String price;
  final String period;
  final IconData icon;
  _Plan(this.title, this.price, this.period, this.icon);
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  _Feature(this.icon, this.title, this.desc);
}
