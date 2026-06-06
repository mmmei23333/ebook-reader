class Book {
  final String id;
  final String title;
  final String author;
  final String filePath;
  final String format; // epub, pdf, txt
  final String? coverPath;
  final DateTime addedAt;
  final DateTime? lastReadAt;
  final int currentPage;
  final int totalPages;
  final List<Bookmark> bookmarks;
  final List<Note> notes;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.format,
    this.coverPath,
    required this.addedAt,
    this.lastReadAt,
    this.currentPage = 0,
    this.totalPages = 0,
    this.bookmarks = const [],
    this.notes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'filePath': filePath,
      'format': format,
      'coverPath': coverPath,
      'addedAt': addedAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      title: map['title'],
      author: map['author'] ?? 'Unknown',
      filePath: map['filePath'],
      format: map['format'],
      coverPath: map['coverPath'],
      addedAt: DateTime.parse(map['addedAt']),
      lastReadAt: map['lastReadAt'] != null
          ? DateTime.parse(map['lastReadAt'])
          : null,
      currentPage: map['currentPage'] ?? 0,
      totalPages: map['totalPages'] ?? 0,
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? format,
    String? coverPath,
    DateTime? addedAt,
    DateTime? lastReadAt,
    int? currentPage,
    int? totalPages,
    List<Bookmark>? bookmarks,
    List<Note>? notes,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      coverPath: coverPath ?? this.coverPath,
      addedAt: addedAt ?? this.addedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      bookmarks: bookmarks ?? this.bookmarks,
      notes: notes ?? this.notes,
    );
  }
}

class Bookmark {
  final String id;
  final String bookId;
  final int page;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.bookId,
    required this.page,
    required this.createdAt,
  });
}

class Note {
  final String id;
  final String bookId;
  final int page;
  final String content;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.bookId,
    required this.page,
    required this.content,
    required this.createdAt,
  });
}
