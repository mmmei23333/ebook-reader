import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book_group.dart';

class LibraryService extends ChangeNotifier {
  static const _groupsKey = 'book_groups';

  List<BookGroup> _groups = [];
  bool _isLoading = false;

  List<BookGroup> get groups => List.unmodifiable(_groups);
  bool get isLoading => _isLoading;

  /// All groups of type book.
  List<BookGroup> get bookGroups =>
      _groups.where((g) => g.type == GroupType.book).toList();

  /// All groups of type comic.
  List<BookGroup> get comicGroups =>
      _groups.where((g) => g.type == GroupType.comic).toList();

  LibraryService() {
    _load();
  }

  // ---- persistence -------------------------------------------------------

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_groupsKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _groups = list
            .map((e) =>
                BookGroup.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading library groups: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _groupsKey,
        jsonEncode(_groups.map((g) => g.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving library groups: $e');
    }
  }

  // ---- public API --------------------------------------------------------

  /// Create a new group. Returns the created group.
  Future<BookGroup> createGroup(String name,
      {GroupType type = GroupType.book}) async {
    final group = BookGroup(name: name, type: type);
    _groups.add(group);
    await _save();
    notifyListeners();
    return group;
  }

  /// Rename an existing group.
  Future<void> renameGroup(String groupId, String newName) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    _groups[index] = _groups[index].copyWith(name: newName);
    await _save();
    notifyListeners();
  }

  /// Delete a group (books are NOT deleted, only the grouping).
  Future<void> deleteGroup(String groupId) async {
    _groups.removeWhere((g) => g.id == groupId);
    await _save();
    notifyListeners();
  }

  /// Add a book to a group.  If [bookId] is already present, this is a no-op.
  Future<void> addBookToGroup(String groupId, String bookId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final group = _groups[index];
    if (group.bookIds.contains(bookId)) return;
    _groups[index] = group.copyWith(
      bookIds: [...group.bookIds, bookId],
    );
    await _save();
    notifyListeners();
  }

  /// Remove a book from a group.
  Future<void> removeBookFromGroup(String groupId, String bookId) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    final group = _groups[index];
    _groups[index] = group.copyWith(
      bookIds: group.bookIds.where((id) => id != bookId).toList(),
    );
    await _save();
    notifyListeners();
  }

  /// Get all groups that contain a specific book.
  List<BookGroup> getGroupsForBook(String bookId) {
    return _groups.where((g) => g.bookIds.contains(bookId)).toList();
  }

  /// Get groups filtered by type.
  List<BookGroup> getGroups({GroupType? type}) {
    if (type == null) return groups;
    return _groups.where((g) => g.type == type).toList();
  }
}
