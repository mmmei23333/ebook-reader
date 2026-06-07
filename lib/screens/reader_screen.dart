import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../services/book_service.dart';

// ─── Reading animation modes ───
enum ReadingAnimation { fadeIn, simulation, slide, scroll }

// ─── Main Reader Screen ───
class ReaderScreen extends StatefulWidget {
  final Book book;
  final List<int>? webFileBytes; // for web platform
  const ReaderScreen({super.key, required this.book, this.webFileBytes});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ── Reader state ──
  int _currentPage = 0;
  bool _showControls = true;
  double _fontSize = 18.0;
  double _lineHeight = 1.8;
  double _paragraphSpacing = 16.0;
  bool _isDarkMode = false;
  int _themeColorIndex = 0;
  bool _followSystemTheme = false;
  ReadingAnimation _readingAnimation = ReadingAnimation.slide;

  // ── TXT reader state ──
  String? _txtContent;
  // ignore: unused_field
  final List<String> _txtPages = [];
  final ScrollController _txtScrollController = ScrollController();

  // ── EPUB reader state ──
  // ignore: unused_field
  epub.EpubBook? _epubBook;
  List<String> _epubChapters = [];
  int _currentChapter = 0;

  // ── Page controller ──
  late PageController _pageController;

  // ── Bookmark / note / reading status state ──
  List<Bookmark> _bookmarks = [];
  List<Note> _notes = [];
  String _readingStatus = '未读'; // 未读, 在读, 读完
  DateTime? _startReadTime;
  int _readingDays = 0;
  Duration _totalReadDuration = Duration.zero;

  // ── Theme colors (background colors for themes) ──
  static const List<Color> _themeColors = [
    Color(0xFFFFF8E7), // light yellow
    Color(0xFFEFF5E3), // green tint
    Color(0xFFFCE4EC), // pink tint
    Color(0xFFE3F2FD), // blue tint
    Color(0xFF2C2C2C), // dark
    Color(0xFF121212), // black
  ];
  static const List<Color> _themeTextColors = [
    Color(0xFF333330),
    Color(0xFF2E4020),
    Color(0xFF4A2030),
    Color(0xFF1A3050),
    Color(0xFFD8D8D8),
    Color(0xFFB0B0B0),
  ];

  Color get _bgColor => _themeColors[_themeColorIndex];
  Color get _textColor => _themeTextColors[_themeColorIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.book.currentPage;
    _pageController = PageController(initialPage: _currentPage);
    _bookmarks = List.from(widget.book.bookmarks);
    _notes = List.from(widget.book.notes);
    _startReadTime = DateTime.now();
    _loadSettings();
    _loadContent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _txtScrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveProgress();
    }
  }

  // ═══════════════════════════════════════════════════
  // Settings persistence
  // ═══════════════════════════════════════════════════
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
      _lineHeight = prefs.getDouble('reader_line_height') ?? 1.8;
      _isDarkMode = prefs.getBool('reader_dark_mode') ?? false;
      _paragraphSpacing = prefs.getDouble('reader_paragraph_spacing') ?? 16.0;
      _themeColorIndex = prefs.getInt('reader_theme_color_index') ?? 0;
      _followSystemTheme = prefs.getBool('reader_follow_system') ?? false;
      _readingAnimation = ReadingAnimation
          .values[prefs.getInt('reader_animation') ?? 2]; // default slide
      _readingDays = prefs.getInt('reader_days_${widget.book.id}') ?? 0;
      _totalReadDuration = Duration(
          seconds: prefs.getInt('reader_total_seconds_${widget.book.id}') ?? 0);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', _fontSize);
    await prefs.setDouble('reader_line_height', _lineHeight);
    await prefs.setBool('reader_dark_mode', _isDarkMode);
    await prefs.setDouble('reader_paragraph_spacing', _paragraphSpacing);
    await prefs.setInt('reader_theme_color_index', _themeColorIndex);
    await prefs.setBool('reader_follow_system', _followSystemTheme);
    await prefs.setInt('reader_animation', _readingAnimation.index);
  }

  // ═══════════════════════════════════════════════════
  // Content loading (TXT, EPUB, PDF)
  // ═══════════════════════════════════════════════════
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

  Future<Uint8List?> _getFileBytes() async {
    if (widget.webFileBytes != null) {
      return Uint8List.fromList(widget.webFileBytes!);
    }
    try {
      final file = File(widget.book.filePath);
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadTxtContent() async {
    try {
      if (widget.webFileBytes != null) {
        setState(() {
          _txtContent = String.fromCharCodes(widget.webFileBytes!);
        });
      } else {
        final file = File(widget.book.filePath);
        final content = await file.readAsString();
        setState(() {
          _txtContent = content;
        });
      }
    } catch (e) {
      setState(() {
        _txtContent = '加载文件失败: $e';
      });
    }
  }

  // Store chapter titles separately
  List<String> _epubChapterTitles = [];

  Future<void> _loadEpubContent() async {
    try {
      final bytes = await _getFileBytes();
      if (bytes == null) {
        setState(() { _epubChapters = ['无法读取文件']; });
        return;
      }
      final book = await epub.EpubReader.readBook(bytes);

      final chapters = <String>[];
      final titles = <String>[];
      // Recursively extract all chapters including sub-chapters
      void extractChapters(List<epub.EpubChapter>? chList) {
        if (chList == null) return;
        for (final ch in chList) {
          String title = ch.Title?.trim() ?? '未命名章节';
          String content = '';
          if (ch.HtmlContent != null) {
            content = _stripHtmlTags(ch.HtmlContent!);
          }
          // Only add if there's actual text content
          final textOnly = content.replaceAll(RegExp(r'\s'), '');
          if (textOnly.isNotEmpty) {
            titles.add(title);
            chapters.add(content);
          }
          // Recurse into sub-chapters
          if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
            extractChapters(ch.SubChapters);
          }
        }
      }
      extractChapters(book.Chapters);

      setState(() {
        _epubBook = book;
        _epubChapters = chapters;
        _epubChapterTitles = titles;
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
    // Extract body content if present
    final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>', dotAll: true).firstMatch(html);
    String content = bodyMatch != null ? bodyMatch.group(1)! : html;
    
    return content
        // Remove style/script blocks entirely
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        // Remove head block
        .replaceAll(RegExp(r'<head[^>]*>.*?</head>', dotAll: true), '')
        // Remove HTML tags but preserve line breaks
        .replaceAll(RegExp(r'<br\s*/?\s*>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<div[^>]*>'), '\n')
        .replaceAll(RegExp(r'</div>'), '\n')
        .replaceAll(RegExp(r'<h[1-6][^>]*>'), '\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n')
        // Remove remaining tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Decode HTML entities
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'&#\d+;'), '')
        // Clean up whitespace
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n')
        .split('\n')
        .map((l) => l.trim())
        .join('\n')
        .trim();
  }

  // ═══════════════════════════════════════════════════
  // Progress saving
  // ═══════════════════════════════════════════════════
  void _saveProgress() {
    int progress = _currentPage;
    if (widget.book.format.toLowerCase() == 'epub') {
      progress = _currentChapter;
    }
    Provider.of<BookService>(context, listen: false)
        .updateReadingProgress(widget.book.id, progress);
  }

  // ═══════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
        },
        child: Stack(
          children: [
            _buildReader(),
            if (_showControls) _buildOverlayControls(),
          ],
        ),
      ),
    );
  }

  // ── Reader content ──
  Widget _buildReader() {
    switch (widget.book.format.toLowerCase()) {
      case 'pdf':
        return _buildPdfReader();
      case 'epub':
        return _buildEpubReader();
      case 'txt':
        return _buildTxtReader();
      default:
        return Center(
          child: Text('不支持的格式',
              style: TextStyle(color: _textColor, fontSize: 16)),
        );
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
      return Center(child: CircularProgressIndicator(color: _textColor));
    }

    return SafeArea(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0) {
            _nextPage();
          } else if (details.primaryVelocity! > 0) {
            _previousPage();
          }
        },
        child: Container(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 30),
          child: SingleChildScrollView(
            controller: _txtScrollController,
            child: SelectableText(
              _txtContent!,
              style: TextStyle(
                fontSize: _fontSize,
                height: _lineHeight,
                color: _textColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEpubReader() {
    if (_epubChapters.isEmpty) {
      return Center(child: CircularProgressIndicator(color: _textColor));
    }

    return SafeArea(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! < 0) {
            _nextChapter();
          } else if (details.primaryVelocity! > 0) {
            _previousChapter();
          }
        },
        child: Container(
          padding:
              const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _epubChapterTitles.isNotEmpty && _currentChapter < _epubChapterTitles.length
                      ? _epubChapterTitles[_currentChapter]
                      : '第 ${_currentChapter + 1} 章',
                  style: TextStyle(
                    fontSize: _fontSize + 4,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                SizedBox(height: _paragraphSpacing),
                SelectableText(
                  _epubChapters[_currentChapter],
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: _lineHeight,
                    color: _textColor.withOpacity(0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Navigation ──
  void _nextPage() {
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

  // ═══════════════════════════════════════════════════
  // Overlay controls (top bar + bottom toolbar)
  // ═══════════════════════════════════════════════════
  Widget _buildOverlayControls() {
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
              _buildProgressBar(),
              _buildBottomToolbar(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar: back + title + icons ──
  Widget _buildTopBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              _saveProgress();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              widget.book.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 22),
            onPressed: _addBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能开发中')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onPressed: _showMoreMenu,
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar() {
    String progressText = '';
    double progressValue = 0;

    if (widget.book.format.toLowerCase() == 'epub' && _epubChapters.isNotEmpty) {
      progressText = '${_currentChapter + 1} / ${_epubChapters.length} 章';
      progressValue = (_currentChapter + 1) / _epubChapters.length;
    } else if (widget.book.totalPages > 0) {
      progressText = '${_currentPage + 1} / ${widget.book.totalPages}';
      progressValue = (_currentPage + 1) / widget.book.totalPages;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text(
            progressText,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                trackHeight: 2,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: progressValue.clamp(0.0, 1.0),
                onChanged: (value) {
                  if (widget.book.format.toLowerCase() == 'epub' &&
                      _epubChapters.isNotEmpty) {
                    final ch = (value * _epubChapters.length)
                        .toInt()
                        .clamp(0, _epubChapters.length - 1);
                    setState(() {
                      _currentChapter = ch;
                      _currentPage = ch;
                    });
                  }
                },
                onChangeEnd: (_) => _saveProgress(),
              ),
            ),
          ),
          Text(
            '${(progressValue * 100).toInt()}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Bottom toolbar: 5 icons ──
  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolbarIcon(Icons.menu_book, '目录', () => _showTocPanel()),
          _toolbarIcon(Icons.edit_note, '笔记', () => _showTocPanel(initialTab: 1)),
          _toolbarIcon(Icons.brightness_6, '亮度', () => _showBrightnessPanel()),
          _toolbarIcon(Icons.format_size, '字体', () => _showFontPanel()),
          _toolbarIcon(Icons.search, '搜索', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('搜索功能开发中')),
            );
          }),
        ],
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = false);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TOC / Notes / Bookmarks Panel
  // ═══════════════════════════════════════════════════
  void _showTocPanel({int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TocNotesBookmarksPanel(
        initialTab: initialTab,
        book: widget.book,
        epubChapters: _epubChapters,
        epubChapterTitles: _epubChapterTitles,
        currentChapter: _currentChapter,
        bookmarks: _bookmarks,
        notes: _notes,
        onChapterTap: (index) {
          setState(() {
            _currentChapter = index;
            _currentPage = index;
          });
          _saveProgress();
        },
        onBookDetailTap: () => _showBookDetail(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Font / Reading Settings Panel
  // ═══════════════════════════════════════════════════
  void _showFontPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FontSettingsPanel(
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        paragraphSpacing: _paragraphSpacing,
        readingAnimation: _readingAnimation,
        themeColorIndex: _themeColorIndex,
        followSystemTheme: _followSystemTheme,
        onFontSizeChanged: (v) {
          setState(() => _fontSize = v);
          _saveSettings();
        },
        onLineHeightChanged: (v) {
          setState(() => _lineHeight = v);
          _saveSettings();
        },
        onParagraphSpacingChanged: (v) {
          setState(() => _paragraphSpacing = v);
          _saveSettings();
        },
        onAnimationChanged: (v) {
          setState(() => _readingAnimation = v);
          _saveSettings();
        },
        onThemeColorChanged: (i) {
          setState(() => _themeColorIndex = i);
          _saveSettings();
        },
        onFollowSystemChanged: (v) {
          setState(() => _followSystemTheme = v);
          _saveSettings();
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Brightness Panel (simple slider)
  // ═══════════════════════════════════════════════════
  void _showBrightnessPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: 160,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_low, size: 20, color: Colors.grey),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Theme.of(context).primaryColor,
                      thumbColor: Theme.of(context).primaryColor,
                    ),
                    child: Slider(
                      value: _themeColorIndex < 4 ? 1.0 : 0.5,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const Icon(Icons.brightness_high, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('深色模式', style: TextStyle(fontSize: 14)),
                const Spacer(),
                Switch(
                  value: _isDarkMode,
                  onChanged: (v) {
                    setState(() {
                      _isDarkMode = v;
                      if (v) {
                        _themeColorIndex = 5;
                      } else {
                        _themeColorIndex = 0;
                      }
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // More menu
  // ═══════════════════════════════════════════════════
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('书籍详情'),
              onTap: () {
                Navigator.pop(context);
                _showBookDetail();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('添加书签'),
              onTap: () {
                Navigator.pop(context);
                _addBookmark();
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: Text(_isDarkMode ? '关闭深色模式' : '开启深色模式'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isDarkMode = !_isDarkMode;
                  _themeColorIndex = _isDarkMode ? 5 : 0;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Bookmark
  // ═══════════════════════════════════════════════════
  void _addBookmark() {
    final newBookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      page: widget.book.format.toLowerCase() == 'epub'
          ? _currentChapter
          : _currentPage,
      createdAt: DateTime.now(),
    );
    setState(() {
      _bookmarks.add(newBookmark);
    });
    Provider.of<BookService>(context, listen: false).updateBook(
      widget.book.copyWith(bookmarks: _bookmarks),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加书签：第 ${newBookmark.page + 1} 页'),
        action: SnackBarAction(label: '查看', onPressed: () => _showTocPanel(initialTab: 2)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Book Detail (full page modal)
  // ═══════════════════════════════════════════════════
  void _showBookDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _BookDetailPage(
          book: widget.book,
          readingStatus: _readingStatus,
          totalReadDuration: _totalReadDuration,
          readingDays: _readingDays,
          startReadTime: _startReadTime,
          onStatusChanged: (status) {
            setState(() => _readingStatus = status);
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOC / Notes / Bookmarks Panel (Stateful bottom sheet)
// ═══════════════════════════════════════════════════════════
class _TocNotesBookmarksPanel extends StatefulWidget {
  final int initialTab;
  final Book book;
  final List<String> epubChapters;
  final List<String> epubChapterTitles;
  final int currentChapter;
  final List<Bookmark> bookmarks;
  final List<Note> notes;
  final ValueChanged<int> onChapterTap;
  final VoidCallback onBookDetailTap;

  const _TocNotesBookmarksPanel({
    required this.initialTab,
    required this.book,
    required this.epubChapters,
    required this.epubChapterTitles,
    required this.currentChapter,
    required this.bookmarks,
    required this.notes,
    required this.onChapterTap,
    required this.onBookDetailTap,
  });

  @override
  State<_TocNotesBookmarksPanel> createState() =>
      _TocNotesBookmarksPanelState();
}

class _TocNotesBookmarksPanelState extends State<_TocNotesBookmarksPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Handle bar ──
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Close button + Tab bar ──
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 15),
                  tabs: const [
                    Tab(text: '目录'),
                    Tab(text: '笔记'),
                    Tab(text: '书签'),
                  ],
                ),
              ),
              const SizedBox(width: 48), // balance
            ],
          ),

          // ── Book info section ──
          GestureDetector(
            onTap: widget.onBookDetailTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Format icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _formatColor(widget.book.format),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.book.format.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.book.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),

          // ── Tab views ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTocTab(),
                _buildNotesTab(),
                _buildBookmarksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _formatColor(String format) {
    switch (format.toLowerCase()) {
      case 'epub':
        return const Color(0xFF4CAF50);
      case 'pdf':
        return const Color(0xFFE53935);
      case 'txt':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  // ── TOC tab ──
  Widget _buildTocTab() {
    if (widget.epubChapters.isEmpty) {
      return const Center(
        child: Text('暂无目录', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: widget.epubChapters.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final chapterTitle = widget.epubChapterTitles.isNotEmpty && index < widget.epubChapterTitles.length
            ? widget.epubChapterTitles[index]
            : '第 ${index + 1} 章';
        final isSelected = index == widget.currentChapter;

        return InkWell(
          onTap: () {
            widget.onChapterTap(index);
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: isSelected ? Colors.grey[100] : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    chapterTitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Notes tab ──
  Widget _buildNotesTab() {
    if (widget.notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无笔记', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
            const SizedBox(height: 8),
            Text('阅读时长按文字即可添加笔记',
                style: TextStyle(color: Colors.grey[350], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.notes.length,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (context, index) {
        final note = widget.notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '第 ${note.page + 1} 页',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bookmarks tab ──
  Widget _buildBookmarksTab() {
    if (widget.bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无书签',
                style: TextStyle(color: Colors.grey[400], fontSize: 15)),
            const SizedBox(height: 8),
            Text('点击顶部书签图标即可添加',
                style: TextStyle(color: Colors.grey[350], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.bookmarks.length,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (context, index) {
        final bm = widget.bookmarks[index];
        return ListTile(
          leading: const Icon(Icons.bookmark, color: Color(0xFFFF9800)),
          title: Text('第 ${bm.page + 1} 页'),
          subtitle: Text(
            '${bm.createdAt.year}-${bm.createdAt.month.toString().padLeft(2, '0')}-${bm.createdAt.day.toString().padLeft(2, '0')} ${bm.createdAt.hour.toString().padLeft(2, '0')}:${bm.createdAt.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          onTap: () {
            widget.onChapterTap(bm.page);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Font / Reading Settings Panel
// ═══════════════════════════════════════════════════════════
class _FontSettingsPanel extends StatefulWidget {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final ReadingAnimation readingAnimation;
  final int themeColorIndex;
  final bool followSystemTheme;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineHeightChanged;
  final ValueChanged<double> onParagraphSpacingChanged;
  final ValueChanged<ReadingAnimation> onAnimationChanged;
  final ValueChanged<int> onThemeColorChanged;
  final ValueChanged<bool> onFollowSystemChanged;

  const _FontSettingsPanel({
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.readingAnimation,
    required this.themeColorIndex,
    required this.followSystemTheme,
    required this.onFontSizeChanged,
    required this.onLineHeightChanged,
    required this.onParagraphSpacingChanged,
    required this.onAnimationChanged,
    required this.onThemeColorChanged,
    required this.onFollowSystemChanged,
  });

  @override
  State<_FontSettingsPanel> createState() => _FontSettingsPanelState();
}

class _FontSettingsPanelState extends State<_FontSettingsPanel> {
  late double _fontSize;
  late double _lineHeight;
  late double _paragraphSpacing;
  late ReadingAnimation _readingAnimation;
  late int _themeColorIndex;
  late bool _followSystemTheme;

  static const List<Color> _themeColors = [
    Color(0xFFFFF8E7),
    Color(0xFFEFF5E3),
    Color(0xFFFCE4EC),
    Color(0xFFE3F2FD),
    Color(0xFF2C2C2C),
    Color(0xFF121212),
  ];

  @override
  void initState() {
    super.initState();
    _fontSize = widget.fontSize;
    _lineHeight = widget.lineHeight;
    _paragraphSpacing = widget.paragraphSpacing;
    _readingAnimation = widget.readingAnimation;
    _themeColorIndex = widget.themeColorIndex;
    _followSystemTheme = widget.followSystemTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle bar ──
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Font size slider ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('小',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Theme.of(context).primaryColor,
                        thumbColor: Theme.of(context).primaryColor,
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: _fontSize,
                        min: 12,
                        max: 32,
                        divisions: 20,
                        onChanged: (v) {
                          setState(() => _fontSize = v);
                          widget.onFontSizeChanged(v);
                        },
                      ),
                    ),
                  ),
                  const Text('大',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${_fontSize.toInt()}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // ── Paragraph spacing ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.format_line_spacing, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('段距', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  _stepperButton(Icons.remove, () {
                    setState(() {
                      _paragraphSpacing =
                          (_paragraphSpacing - 2).clamp(8, 40);
                    });
                    widget.onParagraphSpacingChanged(_paragraphSpacing);
                  }),
                  const SizedBox(width: 12),
                  Text('${_paragraphSpacing.toInt()}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  _stepperButton(Icons.add, () {
                    setState(() {
                      _paragraphSpacing =
                          (_paragraphSpacing + 2).clamp(8, 40);
                    });
                    widget.onParagraphSpacingChanged(_paragraphSpacing);
                  }),
                ],
              ),
            ),

            // ── Line spacing ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.format_textdirection_l_to_r,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('行距', style: TextStyle(fontSize: 14)),
                  const Spacer(),
                  _stepperButton(Icons.remove, () {
                    setState(() {
                      _lineHeight = (_lineHeight - 0.1).clamp(1.0, 3.0);
                    });
                    widget.onLineHeightChanged(_lineHeight);
                  }),
                  const SizedBox(width: 12),
                  Text(_lineHeight.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 12),
                  _stepperButton(Icons.add, () {
                    setState(() {
                      _lineHeight = (_lineHeight + 0.1).clamp(1.0, 3.0);
                    });
                    widget.onLineHeightChanged(_lineHeight);
                  }),
                ],
              ),
            ),

            const Divider(height: 24),

            // ── Reading animation ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('翻页动画',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _animationChip('淡入', ReadingAnimation.fadeIn),
                      _animationChip('仿真', ReadingAnimation.simulation),
                      _animationChip('平移', ReadingAnimation.slide),
                      _animationChip('滚动', ReadingAnimation.scroll),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // ── Links ──
            _linkTile('阅读排版', () {}),
            _linkTile('更多设置', () {}),

            const Divider(height: 24),

            // ── Theme colors ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('主题色',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Text('跟随系统',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 8),
                      Switch(
                        value: _followSystemTheme,
                        onChanged: (v) {
                          setState(() => _followSystemTheme = v);
                          widget.onFollowSystemChanged(v);
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(_themeColors.length, (i) {
                      final selected = i == _themeColorIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _themeColorIndex = i);
                          widget.onThemeColorChanged(i);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 14),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _themeColors[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300]!,
                              width: selected ? 2.5 : 1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                    )
                                  ]
                                : null,
                          ),
                          child: selected
                              ? Icon(Icons.check,
                                  size: 18,
                                  color: i >= 4 ? Colors.white : Colors.black54)
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── More themes ──
            _linkTile('更多主题', () {}),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: Colors.grey[700]),
      ),
    );
  }

  Widget _animationChip(String label, ReadingAnimation mode) {
    final selected = _readingAnimation == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _readingAnimation = mode);
        widget.onAnimationChanged(mode);
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? Theme.of(context).primaryColor : Colors.grey[300]!,
      ),
    );
  }

  Widget _linkTile(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Book Detail Page
// ═══════════════════════════════════════════════════════════
class _BookDetailPage extends StatefulWidget {
  final Book book;
  final String readingStatus;
  final Duration totalReadDuration;
  final int readingDays;
  final DateTime? startReadTime;
  final ValueChanged<String> onStatusChanged;

  const _BookDetailPage({
    required this.book,
    required this.readingStatus,
    required this.totalReadDuration,
    required this.readingDays,
    required this.startReadTime,
    required this.onStatusChanged,
  });

  @override
  State<_BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<_BookDetailPage> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.readingStatus;
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final progress = book.totalPages > 0
        ? ((book.currentPage / book.totalPages) * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('书籍详情',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Book cover + title + author ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover placeholder
                Container(
                  width: 90,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _coverColor(book.format),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book,
                            color: Colors.white.withOpacity(0.8), size: 32),
                        const SizedBox(height: 6),
                        Text(
                          book.format.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      // Metadata row
                      Text(
                        '$progress% · ${_formatFileSize(book.filePath)} · ${book.format.toUpperCase()} · ${_estimateWordCount()}字',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Reading status toggles ──
            Row(
              children: [
                const Text('阅读状态',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statusChip('未读'),
                const SizedBox(width: 12),
                _statusChip('在读'),
                const SizedBox(width: 12),
                _statusChip('读完'),
              ],
            ),

            const SizedBox(height: 28),

            // ── Reading statistics ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('阅读统计',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statItem('累计时长',
                          _formatDuration(widget.totalReadDuration)),
                      _statItem('阅读天数', '${widget.readingDays}天'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statItem(
                          '开始阅读',
                          widget.startReadTime != null
                              ? _formatDate(widget.startReadTime!)
                              : '--'),
                      _statItem(
                          '上次阅读',
                          book.lastReadAt != null
                              ? _formatDate(book.lastReadAt!)
                              : '--'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _coverColor(String format) {
    switch (format.toLowerCase()) {
      case 'epub':
        return const Color(0xFF4CAF50);
      case 'pdf':
        return const Color(0xFFE53935);
      case 'txt':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String label) {
    final selected = _status == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _status = label);
          widget.onStatusChanged(label);
        },
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color:
                  selected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}小时${d.inMinutes.remainder(60)}分钟';
    }
    return '${d.inMinutes}分钟';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes > 1024 * 1024) {
          return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
        }
        return '${(bytes / 1024).toStringAsFixed(0)} KB';
      }
    } catch (_) {}
    return '--';
  }

  String _estimateWordCount() {
    // Rough estimate based on format
    return (widget.book.totalPages * 500).toString();
  }
}
