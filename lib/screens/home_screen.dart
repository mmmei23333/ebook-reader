import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/book_service.dart';
import '../services/stats_service.dart';
import '../models/book.dart';
import 'reader_screen.dart';
import 'side_menu.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Web platform: store file bytes in memory (key = filePath)
  static final Map<String, List<int>> _webFileBytes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showImportMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '导入书籍',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildImportOption(
                icon: Icons.wifi,
                title: 'WiFi传书',
                subtitle: '通过无线网络传输书籍',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement WiFi transfer
                },
              ),
              _buildImportOption(
                icon: Icons.download,
                title: '我的下载',
                subtitle: '从下载目录导入书籍',
                onTap: () {
                  Navigator.pop(context);
                  _importFromDownloads();
                },
              ),
              _buildImportOption(
                icon: Icons.cloud,
                title: '网盘和连接',
                subtitle: '从云盘或网络连接导入',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement cloud import
                },
              ),
              const Divider(),
              _buildImportOption(
                icon: Icons.create_new_folder,
                title: '新建分组',
                subtitle: '创建新的书籍分组',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement create group
                },
              ),
              _buildImportOption(
                icon: Icons.folder_open,
                title: '分组管理',
                subtitle: '管理已有书籍分组',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement group management
                },
              ),
              _buildImportOption(
                icon: Icons.file_open,
                title: '本地导入',
                subtitle: '从本地存储选择文件',
                onTap: () {
                  Navigator.pop(context);
                  _importBook();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      drawerEdgeDragWidth: 40,
      onDrawerChanged: (isOpened) {},
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Detect left swipe (negative velocity = swipe left to right opens drawer)
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            _openDrawer();
          }
        },
        child: Column(
          children: [
            // Status bar padding
            SizedBox(height: MediaQuery.of(context).padding.top),
            // Top bar
            _buildTopBar(),
            // Tab bar
            _buildTabBar(),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookGrid(),
                  _buildMangaGrid(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Hamburger menu
          IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: _openDrawer,
          ),
          const SizedBox(width: 8),
          // Title
          const Text(
            '书库',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // Reading duration
          Consumer<StatsService>(
            builder: (context, stats, child) {
              final minutes = stats.totalReadingMinutes;
              final hours = minutes ~/ 60;
              final mins = minutes % 60;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '阅读时长 ${hours > 0 ? "${hours}h" : ""}${mins}min',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Import button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              onPressed: _showImportMenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        tabs: const [
          Tab(text: '书库'),
          Tab(text: '漫画'),
        ],
      ),
    );
  }

  Widget _buildBookGrid() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        if (bookService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookService.books.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.52,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: bookService.books.length,
          itemBuilder: (context, index) {
            final book = bookService.books[index];
            return _BookCard(
              book: book,
              onTap: () => _openBook(book),
              onLongPress: () => _showBookOptions(book),
            );
          },
        );
      },
    );
  }

  Widget _buildMangaGrid() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        // Filter manga/comic books (cbz, cbr, etc.)
        final mangaBooks = bookService.books
            .where((b) => ['cbz', 'cbr', 'cb7'].contains(b.format.toLowerCase()))
            .toList();

        if (mangaBooks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mood_bad,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无漫画',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击 + 导入漫画文件',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.52,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: mangaBooks.length,
          itemBuilder: (context, index) {
            final book = mangaBooks[index];
            return _BookCard(
              book: book,
              onTap: () => _openBook(book),
              onLongPress: () => _showBookOptions(book),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            '书架空空如也',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角 + 导入书籍',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showImportMenu,
            icon: const Icon(Icons.add),
            label: const Text('导入书籍'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromDownloads() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'txt', 'cbz', 'cbr', 'cb7'],
      );

      if (result != null) {
        final file = result.files.first;
        // On web, path is unavailable — use name as key
        final filePath = kIsWeb ? file.name : (file.path ?? file.name);
        final book = Book(
          id: const Uuid().v4(),
          title: file.name.replaceAll(RegExp(r'\.(epub|pdf|txt|cbz|cbr|cb7)$'), ''),
          author: '未知',
          filePath: filePath,
          format: file.extension ?? 'unknown',
          addedAt: DateTime.now(),
          totalPages: 100,
        );

        if (kIsWeb && file.bytes != null) {
          _webFileBytes[filePath] = file.bytes!;
        }

        await Provider.of<BookService>(context, listen: false).addBook(book);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入: ${book.title}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _importBook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'txt', 'cbz', 'cbr', 'cb7'],
      );

      if (result != null) {
        final file = result.files.first;
        final filePath = kIsWeb ? file.name : (file.path ?? file.name);
        final book = Book(
          id: const Uuid().v4(),
          title: file.name.replaceAll(RegExp(r'\.(epub|pdf|txt|cbz|cbr|cb7)$'), ''),
          author: '未知',
          filePath: filePath,
          format: file.extension ?? 'unknown',
          addedAt: DateTime.now(),
          totalPages: 100,
        );

        if (kIsWeb && file.bytes != null) {
          _webFileBytes[filePath] = file.bytes!;
        }

        await Provider.of<BookService>(context, listen: false).addBook(book);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导入: ${book.title}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  void _openBook(Book book) {
    final webBytes = _webFileBytes[book.filePath];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book, webFileBytes: webBytes),
      ),
    );
  }

  void _showBookOptions(Book book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  book.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('书籍信息'),
                onTap: () {
                  Navigator.pop(context);
                  _showBookInfo(book);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeBook(book);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBookInfo(Book book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(book.title),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('作者: ${book.author}'),
              Text('格式: ${book.format.toUpperCase()}'),
              Text('添加时间: ${book.addedAt.toString().split('.')[0]}'),
              if (book.lastReadAt != null)
                Text('上次阅读: ${book.lastReadAt.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _removeBook(Book book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除书籍'),
          content: Text('确定要从书库中删除《${book.title}》吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<BookService>(context, listen: false)
                    .removeBook(book.id);
                Navigator.pop(context);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _BookCard({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (progress * 100).toInt();
    final isUnread = book.currentPage == 0 && book.lastReadAt == null;
    final isFinished = progress >= 1.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Cover image or format icon
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getBookIcon(book.format),
                            size: 40,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              book.format.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    if (isUnread)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '未读',
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (isFinished)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '读完',
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    // Progress indicator at bottom
                    if (progress > 0 && !isFinished)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.black.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            book.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          // Progress text and read status
          Row(
            children: [
              Text(
                '$progressPercent%',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (!isUnread && !isFinished)
                Text(
                  '阅读中',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getBookIcon(String format) {
    switch (format.toLowerCase()) {
      case 'epub':
        return Icons.book;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
        return Icons.text_snippet;
      case 'cbz':
      case 'cbr':
      case 'cb7':
        return Icons.collections;
      default:
        return Icons.description;
    }
  }
}

class BookSearchDelegate extends SearchDelegate {
  final BookService bookService;

  BookSearchDelegate(this.bookService);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = bookService.searchBooks(query);

    if (results.isEmpty) {
      return const Center(
        child: Text('未找到书籍'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final book = results[index];
        return ListTile(
          leading: const Icon(Icons.book),
          title: Text(book.title),
          subtitle: Text(book.author),
          onTap: () {
            close(context, book);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReaderScreen(book: book),
              ),
            );
          },
        );
      },
    );
  }
}
