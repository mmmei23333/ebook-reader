import 'package:flutter/material.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

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
        title: const Text('使用指南', style: TextStyle(color: Color(0xFF333333), fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGuideItem(
            Icons.menu_book,
            '导入书籍',
            '支持epub、mobi、azw、txt、pdf等多种格式。点击右上角"+"号导入本地书籍，或通过WiFi传书从电脑传输。',
          ),
          _buildGuideItem(
            Icons.touch_app,
            '阅读操作',
            '左右滑动翻页，上下滑动滚动阅读。点击屏幕中央唤出工具栏，可调整亮度、字号、背景色等。',
          ),
          _buildGuideItem(
            Icons.bookmark,
            '书签与笔记',
            '长按文字可选择、复制、标注、添加笔记。点击工具栏书签图标快速添加书签。',
          ),
          _buildGuideItem(
            Icons.folder,
            '书架管理',
            '长按书籍可移动分组、删除、导出。支持自定义分类和排序方式。',
          ),
          _buildGuideItem(
            Icons.cloud_sync,
            '数据同步',
            '在设置中开启云同步，可在多设备间同步阅读进度、书签和笔记。',
          ),
          _buildGuideItem(
            Icons.brush,
            '个性化外观',
            '在外观设置中切换主题色、深色模式，调整书架显示效果，打造专属阅读空间。',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2196F3), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 6),
                Text(content, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
