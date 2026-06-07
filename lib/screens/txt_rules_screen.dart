import 'package:flutter/material.dart';

class TxtRulesScreen extends StatefulWidget {
  const TxtRulesScreen({super.key});

  @override
  State<TxtRulesScreen> createState() => _TxtRulesScreenState();
}

class _TxtRulesScreenState extends State<TxtRulesScreen> {
  bool _temporaryEffect = false;
  final TextEditingController _regexController = TextEditingController();
  final TextEditingController _maxCharsController = TextEditingController(text: '50000');

  final List<String> _myRules = [
    r'第.{1,5}章',
    r'Chapter \d+',
    r'第.{1,3}回',
  ];

  @override
  void dispose() {
    _regexController.dispose();
    _maxCharsController.dispose();
    super.dispose();
  }

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
        title: const Text('TXT分章规则', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('章节最大字数', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                const SizedBox(height: 8),
                TextField(
                  controller: _maxCharsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '请使用正则表达式语法。每条规则占一行，匹配到的内容将作为新章节的开始。',
                    style: TextStyle(fontSize: 13, color: Colors.orange[800], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('临时生效', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
              subtitle: Text('仅对本次导入的文件生效', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              value: _temporaryEffect,
              onChanged: (v) => setState(() => _temporaryEffect = v),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('添加正则规则', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                const SizedBox(height: 8),
                TextField(
                  controller: _regexController,
                  decoration: InputDecoration(
                    hintText: '输入正则表达式...',
                    hintStyle: TextStyle(color: Colors.grey[300]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (_regexController.text.isNotEmpty) {
                            setState(() {
                              _myRules.add(_regexController.text);
                              _regexController.clear();
                            });
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('添加'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('使用'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('我的正则', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: _myRules.asMap().entries.map((entry) {
                return ListTile(
                  leading: Icon(Icons.code, color: Colors.grey[400], size: 20),
                  title: Text(entry.value, style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Color(0xFF333333))),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                    onPressed: () => setState(() => _myRules.removeAt(entry.key)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
