import 'package:flutter_test/flutter_test.dart';
import 'package:ebook_reader/models/book.dart';

void main() {
  group('Book Model', () {
    test('should create a book instance', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/book.epub',
        format: 'epub',
        addedAt: DateTime.now(),
        totalPages: 100,
      );

      expect(book.id, '1');
      expect(book.title, 'Test Book');
      expect(book.author, 'Test Author');
      expect(book.format, 'epub');
    });

    test('should convert to and from map', () {
      final book = Book(
        id: '1',
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/path/to/book.epub',
        format: 'epub',
        addedAt: DateTime.now(),
        totalPages: 100,
      );

      final map = book.toMap();
      final bookFromMap = Book.fromMap(map);

      expect(bookFromMap.id, book.id);
      expect(bookFromMap.title, book.title);
      expect(bookFromMap.author, book.author);
    });
  });
}
