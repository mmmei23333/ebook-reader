import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['日', '周', '月', '年', '总'];
  DateTime _currentDate = DateTime.now();

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
        title: const Text('统计', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF333333), size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTabBar(),
          const SizedBox(height: 20),
          _buildReadingTime(),
          const SizedBox(height: 16),
          _buildDateNav(),
          const SizedBox(height: 16),
          _buildMetricCards(),
          const SizedBox(height: 16),
          _buildProgressSection(),
          const SizedBox(height: 16),
          _buildSessionList(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(_tabs[i], style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? Colors.white : const Color(0xFF666666),
                  )),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReadingTime() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text('1小时40分钟', style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          )),
          const SizedBox(height: 4),
          Text('阅读时长', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDateNav() {
    final dateStr = '${_currentDate.year}年${_currentDate.month}月${_currentDate.day}日';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF999999)),
          onPressed: () => setState(() => _currentDate = _currentDate.subtract(const Duration(days: 1))),
        ),
        Text(dateStr, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF999999)),
          onPressed: () => setState(() => _currentDate = _currentDate.add(const Duration(days: 1))),
        ),
      ],
    );
  }

  Widget _buildMetricCards() {
    final metrics = [
      _Metric('在读', '3', '本'),
      _Metric('读完', '12', '本'),
      _Metric('阅读次数', '28', '次'),
      _Metric('笔记', '5', ''),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
      ),
      itemCount: metrics.length,
      itemBuilder: (ctx, i) {
        final m = metrics[i];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(m.label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: m.value, style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )),
                  TextSpan(text: ' ${m.unit}', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('今日阅读进度', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('已阅读 1小时40分钟', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              Text('目标 2小时', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.83,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList() {
    final sessions = [
      _Session('09:30 - 10:15', '45分钟'),
      _Session('14:00 - 14:35', '35分钟'),
      _Session('20:00 - 20:20', '20分钟'),
    ];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text('阅读记录', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ),
          ...sessions.map((s) => ListTile(
            leading: Icon(Icons.access_time, color: Colors.grey[400], size: 20),
            title: Text(s.timeRange, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
            trailing: Text(s.duration, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final String unit;
  _Metric(this.label, this.value, this.unit);
}

class _Session {
  final String timeRange;
  final String duration;
  _Session(this.timeRange, this.duration);
}
