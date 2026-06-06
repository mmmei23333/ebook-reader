import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/book_service.dart';
import '../models/book.dart';
import 'reader_screen.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mei 阅读器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: BookSearchDelegate(
                  Provider.of<BookService>(context, listen: false),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: '书架',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: '最近',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importBook,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildLibrary();
      case 1:
        return _buildRecent();
      case 2:
        return _buildSettings();
      default:
        return _buildLibrary();
    }
  }

  Widget _buildLibrary() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        if (bookService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (bookService.books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '书架空空如也',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '点击 + 导入书籍',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
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

  Widget _buildRecent() {
    return Consumer<BookService>(
      builder: (context, bookService, child) {
        final recentBooks = bookService.getRecentlyRead();

        if (recentBooks.isEmpty) {
          return const Center(
            child: Text('暂无阅读记录'),
          );
        }

        return ListView.builder(
          itemCount: recentBooks.length,
          itemBuilder: (context, index) {
            final book = recentBooks[index];
            return ListTile(
              leading: _buildBookCover(book, size: 40),
              title: Text(book.title),
              subtitle: Text(book.author),
              trailing: Text(
                '${(book.currentPage / book.totalPages * 100).toStringAsFixed(0)}%',
              ),
              onTap: () => _openBook(book),
            );
          },
        );
      },
    );
  }

  Widget _buildSettings() {
    final user = FirebaseAuth.instance.currentUser;
    return ListView(
      children: [
        // User info section
        if (user != null)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.email?[0].toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email ?? '未登录',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.emailVerified ? '已验证' : '未验证',
                        style: TextStyle(
                          color: user.emailVerified ? Colors.green : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('深色模式'),
          trailing: Switch(
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              // TODO: Implement theme switching
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.font_download),
          title: const Text('字体大小'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Implement font size settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('关于'),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Mei 阅读器',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2024 Mei 阅读器',
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(
            '退出登录',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('确认退出'),
                content: const Text('确定要退出登录吗？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确认'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await FirebaseAuth.instance.signOut();
            }
          },
        ),
      ],
    );
  }

  Widget _buildBookCover(Book book, {double size = 100}) {
    return Container(
      width: size,
      height: size * 1.4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getBookIcon(book.format),
              size: size * 0.4,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                book.title,
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      default:
        return Icons.description;
    }
  }

  Future<void> _importBook() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'pdf', 'txt'],
      );

      if (result != null) {
        final file = result.files.first;
        final book = Book(
          id: const Uuid().v4(),
          title: file.name.replaceAll(RegExp(r'\.(epub|pdf|txt)$'), ''),
          author: 'Unknown',
          filePath: file.path!,
          format: file.extension ?? 'unknown',
          addedAt: DateTime.now(),
          totalPages: 100, // TODO: Get actual page count
        );

        await Provider.of<BookService>(context, listen: false).addBook(book);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added: ${book.title}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing book: $e')),
        );
      }
    }
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReaderScreen(book: book),
      ),
    );
  }

  void _showBookOptions(Book book) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Book Info'),
                onTap: () {
                  Navigator.pop(context);
                  _showBookInfo(book);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove'),
                onTap: () {
                  Navigator.pop(context);
                  _removeBook(book);
                },
              ),
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
              Text('Author: ${book.author}'),
              Text('Format: ${book.format.toUpperCase()}'),
              Text('Added: ${book.addedAt.toString().split('.')[0]}'),
              if (book.lastReadAt != null)
                Text('Last read: ${book.lastReadAt.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
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
          title: const Text('Remove Book'),
          content: Text('Remove "${book.title}" from library?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<BookService>(context, listen: false)
                    .removeBook(book.id);
                Navigator.pop(context);
              },
              child: const Text('Remove'),
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
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Center(
                  child: Icon(
                    _getBookIcon(book.format),
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      book.author,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        child: Text('No books found'),
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
