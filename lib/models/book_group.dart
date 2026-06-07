import 'package:uuid/uuid.dart';

enum GroupType { book, comic }

class BookGroup {
  static const _uuid = Uuid();

  final String id;
  final String name;
  final GroupType type;
  final List<String> bookIds;

  BookGroup({
    String? id,
    required this.name,
    this.type = GroupType.book,
    this.bookIds = const [],
  }) : id = id ?? _uuid.v4();

  int get bookCount => bookIds.length;

  bool containsBook(String bookId) => bookIds.contains(bookId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type == GroupType.comic ? 'comic' : 'book',
      'bookIds': bookIds,
    };
  }

  factory BookGroup.fromMap(Map<String, dynamic> map) {
    return BookGroup(
      id: map['id'],
      name: map['name'],
      type: map['type'] == 'comic' ? GroupType.comic : GroupType.book,
      bookIds: List<String>.from(map['bookIds'] ?? []),
    );
  }

  BookGroup copyWith({
    String? id,
    String? name,
    GroupType? type,
    List<String>? bookIds,
  }) {
    return BookGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      bookIds: bookIds ?? this.bookIds,
    );
  }
}
