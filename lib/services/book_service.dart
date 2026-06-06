import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';

class BookService extends ChangeNotifier {
  List<Book> _books = [];
  Book? _currentBook;
  bool _isLoading = false;

  List<Book> get books => _books;
  Book? get currentBook => _currentBook;
  bool get isLoading => _isLoading;

  BookService() {
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList('books') ?? [];
      _books = booksJson.map((json) => Book.fromMap(jsonDecode(json))).toList();
    } catch (e) {
      debugPrint('Error loading books: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = _books.map((book) => jsonEncode(book.toMap())).toList();
      await prefs.setStringList('books', booksJson);
    } catch (e) {
      debugPrint('Error saving books: $e');
    }
  }

  Future<void> addBook(Book book) async {
    _books.add(book);
    await _saveBooks();
    notifyListeners();
  }

  Future<void> removeBook(String bookId) async {
    _books.removeWhere((book) => book.id == bookId);
    await _saveBooks();
    notifyListeners();
  }

  Future<void> updateBook(Book updatedBook) async {
    final index = _books.indexWhere((book) => book.id == updatedBook.id);
    if (index != -1) {
      _books[index] = updatedBook;
      await _saveBooks();
      notifyListeners();
    }
  }

  void setCurrentBook(Book? book) {
    _currentBook = book;
    notifyListeners();
  }

  Future<void> updateReadingProgress(String bookId, int currentPage) async {
    final index = _books.indexWhere((book) => book.id == bookId);
    if (index != -1) {
      _books[index] = _books[index].copyWith(
        currentPage: currentPage,
        lastReadAt: DateTime.now(),
      );
      await _saveBooks();
      notifyListeners();
    }
  }

  List<Book> getRecentlyRead({int limit = 10}) {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) => (b.lastReadAt ?? b.addedAt)
          .compareTo(a.lastReadAt ?? a.addedAt));
    return sorted.take(limit).toList();
  }

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books;
    final lowerQuery = query.toLowerCase();
    return _books.where((book) =>
        book.title.toLowerCase().contains(lowerQuery) ||
        book.author.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
