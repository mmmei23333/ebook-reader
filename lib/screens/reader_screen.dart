import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/book.dart';
import '../services/book_service.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _currentPage = 0;
  bool _showControls = true;
  double _fontSize = 16.0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // TODO: Load user preferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
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
        return const Center(
          child: Text('Unsupported format'),
        );
    }
  }

  Widget _buildPdfReader() {
    return PdfViewer.uri(
      Uri.file(widget.book.filePath),
      initialPageNumber: _currentPage,
      onPageChanged: (page) {
        setState(() {
          _currentPage = page ?? 0;
        });
        _saveProgress();
      },
    );
  }

  Widget _buildEpubReader() {
    // TODO: Implement EPUB reader
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book, size: 100),
          const SizedBox(height: 16),
          Text(
            'EPUB Reader',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('EPUB support coming soon'),
        ],
      ),
    );
  }

  Widget _buildTxtReader() {
    // TODO: Implement TXT reader
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.text_snippet, size: 100),
          const SizedBox(height: 16),
          Text(
            'TXT Reader',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text('TXT support coming soon'),
        ],
      ),
    );
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
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.bookmark),
          onPressed: _addBookmark,
        ),
        IconButton(
          icon: const Icon(Icons.note_add),
          onPressed: _addNote,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page ${_currentPage + 1}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${(_currentPage / widget.book.totalPages * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _currentPage.toDouble(),
            min: 0,
            max: widget.book.totalPages.toDouble() - 1,
            onChanged: (value) {
              setState(() {
                _currentPage = value.toInt();
              });
            },
            onChangeEnd: (value) {
              _saveProgress();
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.text_decrease, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _fontSize = (_fontSize - 2).clamp(10, 32);
                  });
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
                    _fontSize = (_fontSize + 2).clamp(10, 32);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveProgress() {
    Provider.of<BookService>(context, listen: false)
        .updateReadingProgress(widget.book.id, _currentPage);
  }

  void _addBookmark() {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmark added')),
    );
  }

  void _addNote() {
    // TODO: Implement note functionality
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your note...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Save note
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note added')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
