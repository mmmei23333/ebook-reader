import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with WidgetsBindingObserver {
  int _currentPage = 0;
  bool _showControls = true;
  double _fontSize = 18.0;
  double _lineHeight = 1.8;
  bool _isDarkMode = false;

  // TXT reader state
  String? _txtContent;
  List<String> _txtPages = [];
  final ScrollController _txtScrollController = ScrollController();

  // EPUB reader state
  epub.EpubBook? _epubBook;
  List<String> _epubChapters = [];
  int _currentChapter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.book.currentPage;
    _loadSettings();
    _loadContent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _txtScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveProgress();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
      _lineHeight = prefs.getDouble('reader_line_height') ?? 1.8;
      _isDarkMode = prefs.getBool('reader_dark_mode') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', _fontSize);
    await prefs.setDouble('reader_line_height', _lineHeight);
    await prefs.setBool('reader_dark_mode', _isDarkMode);
  }

  Future<void> _loadContent() async {
    switch (widget.book.format.toLowerCase()) {
      case 'txt':
        await _loadTxtContent();
        break;
      case 'epub':
        await _loadEpubContent();
        break;
    }
  }

  Future<void> _loadTxtContent() async {
    try {
      final file = File(widget.book.filePath);
      final content = await file.readAsString();
      setState(() {
        _txtContent = content;
      });
    } catch (e) {
      setState(() {
        _txtContent = '加载文件失败: $e';
      });
    }
  }

  Future<void> _loadEpubContent() async {
    try {
      final file = File(widget.book.filePath);
      final bytes = await file.readAsBytes();
      final book = await epub.EpubReader.readBook(bytes);

      final chapters = <String>[];
      if (book.Chapters != null) {
        for (final chapter in book.Chapters!) {
          String chapterTitle = chapter.Title ?? '未命名章节';
          String chapterContent = '';

          if (chapter.HtmlContent != null) {
            // Strip HTML tags for plain text display
            chapterContent = _stripHtmlTags(chapter.HtmlContent!);
          }

          chapters.add('$chapterTitle\n\n$chapterContent');
        }
      }

      setState(() {
        _epubBook = book;
        _epubChapters = chapters;
        if (_epubChapters.isNotEmpty) {
          _currentChapter = (_currentPage).clamp(0, _epubChapters.length - 1);
        }
      });
    } catch (e) {
      setState(() {
        _epubChapters = ['加载 EPUB 失败: $e'];
      });
    }
  }

  String _stripHtmlTags(String html) {
    // Simple HTML tag removal
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            _buildReader(),
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildReader() {
    switch (widget.book.format.toLowerCase()) {
      case 'pdf':
        return _buildPdfReader();
      case 'epub':
        return _buildEpubReader();
      case 'txt':
        return _buildTxtReader();
      default:
        return const Center(child: Text('不支持的格式'));
    }
  }

  Widget _buildPdfReader() {
    return PdfViewer.uri(
      Uri.file(widget.book.filePath),
      initialPageNumber: _currentPage,
    );
  }

  Widget _buildTxtReader() {
    if (_txtContent == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < 0) {
          // Swipe left - next page
          _nextPage();
        } else if (details.primaryVelocity! > 0) {
          // Swipe right - previous page
          _previousPage();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          controller: _txtScrollController,
          child: SelectableText(
            _txtContent!,
            style: TextStyle(
              fontSize: _fontSize,
              height: _lineHeight,
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpubReader() {
    if (_epubChapters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < 0) {
          _nextChapter();
        } else if (details.primaryVelocity! > 0) {
          _previousChapter();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter title
              Text(
                '第 ${_currentChapter + 1} 章',
                style: TextStyle(
                  fontSize: _fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              // Chapter content
              SelectableText(
                _epubChapters[_currentChapter],
                style: TextStyle(
                  fontSize: _fontSize,
                  height: _lineHeight,
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    // For TXT, we use scroll position to track progress
    _saveProgress();
  }

  void _previousPage() {
    _saveProgress();
  }

  void _nextChapter() {
    if (_currentChapter < _epubChapters.length - 1) {
      setState(() {
        _currentChapter++;
        _currentPage = _currentChapter;
      });
      _saveProgress();
    }
  }

  void _previousChapter() {
    if (_currentChapter > 0) {
      setState(() {
        _currentChapter--;
        _currentPage = _currentChapter;
      });
      _saveProgress();
    }
  }

  Widget _buildControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: Colors.black54,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      title: Text(
        widget.book.title,
        style: const TextStyle(fontSize: 16),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _saveProgress();
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
            _saveSettings();
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark),
          onPressed: _addBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.toc),
          onPressed: _showChapterList,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress indicator
          if (widget.book.format.toLowerCase() == 'epub' && _epubChapters.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第 ${_currentChapter + 1}/${_epubChapters.length} 章',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  '${((_currentChapter + 1) / _epubChapters.length * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          if (widget.book.format.toLowerCase() == 'epub' && _epubChapters.isNotEmpty)
            Slider(
              value: _currentChapter.toDouble(),
              min: 0,
              max: (_epubChapters.length - 1).toDouble(),
              onChanged: (value) {
                setState(() {
                  _currentChapter = value.toInt();
                  _currentPage = _currentChapter;
                });
              },
              onChangeEnd: (value) {
                _saveProgress();
              },
            ),
          const SizedBox(height: 8),
          // Font size control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.text_decrease, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _fontSize = (_fontSize - 2).clamp(12, 32);
                  });
                  _saveSettings();
                },
              ),
              Text(
                '${_fontSize.toInt()}pt',
                style: const TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _fontSize = (_fontSize + 2).clamp(12, 32);
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Line height control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.format_line_spacing, color: Colors.white70, size: 20),
              Expanded(
                child: Slider(
                  value: _lineHeight,
                  min: 1.2,
                  max: 3.0,
                  divisions: 18,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                  onChanged: (value) {
                    setState(() {
                      _lineHeight = value;
                    });
                  },
                  onChangeEnd: (value) {
                    _saveSettings();
                  },
                ),
              ),
              Text(
                '${_lineHeight.toStringAsFixed(1)}x',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveProgress() {
    int progress = _currentPage;
    if (widget.book.format.toLowerCase() == 'epub') {
      progress = _currentChapter;
    }
    Provider.of<BookService>(context, listen: false)
        .updateReadingProgress(widget.book.id, progress);
  }

  void _addBookmark() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加书签：第 ${_currentPage + 1} 页'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showChapterList() {
    if (widget.book.format.toLowerCase() != 'epub' || _epubChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目录导航仅支持 EPUB 格式')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '第 '
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _epubChapters.length,
                  itemBuilder: (context, index) {
                    final chapterTitle = _epubChapters[index].split('\n').first;
                    return ListTile(
                      title: Text(
                        chapterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: index == _currentChapter,
                      onTap: () {
                        setState(() {
                          _currentChapter = index;
                          _currentPage = index;
                        });
                        _saveProgress();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
