import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/backup_info.dart';

class BackupService extends ChangeNotifier {
  static const _metaKey = 'backup_meta_list';
  static const _autoBackupKey = 'auto_backup_enabled';
  static const _backupDirName = 'backups';
  static const _uuid = Uuid();

  List<BackupInfo> _backups = [];
  bool _autoBackupEnabled = false;
  bool _isLoading = false;

  List<BackupInfo> get backups =>
      List.unmodifiable(_backups..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  bool get autoBackupEnabled => _autoBackupEnabled;
  bool get isLoading => _isLoading;

  BackupService() {
    _load();
  }

  // ---- persistence -------------------------------------------------------

  Future<Directory> _getBackupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$_backupDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoBackupEnabled = prefs.getBool(_autoBackupKey) ?? false;

      final metaJson = prefs.getString(_metaKey);
      if (metaJson != null) {
        final list = jsonDecode(metaJson) as List;
        _backups = list
            .map((e) =>
                BackupInfo.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      // Prune entries whose files no longer exist
      final dir = await _getBackupDir();
      final existing =
          dir.listSync().map((f) => f.path).toSet();
      _backups.removeWhere((b) {
        final path = '${dir.path}/${b.id}.json';
        return !existing.contains(path);
      });
      await _saveMeta();
    } catch (e) {
      debugPrint('Error loading backups: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _metaKey,
        jsonEncode(_backups.map((b) => b.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving backup meta: $e');
    }
  }

  // ---- public API --------------------------------------------------------

  /// Create a new backup.  [data] is the JSON-serialisable map to store.
  Future<BackupInfo?> createBackup(
    Map<String, dynamic> data, {
    bool auto = false,
  }) async {
    try {
      final dir = await _getBackupDir();
      final id = _uuid.v4();
      final file = File('${dir.path}/$id.json');

      final content = jsonEncode(data);
      await file.writeAsString(content);
      final stat = await file.stat();

      final info = BackupInfo(
        id: id,
        timestamp: DateTime.now(),
        fileSize: stat.size,
        isAutoBackup: auto,
      );

      _backups.insert(0, info);
      await _saveMeta();
      notifyListeners();
      return info;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }

  /// Get the raw data map stored in a backup.
  Future<Map<String, dynamic>?> restoreBackup(String id) async {
    try {
      final dir = await _getBackupDir();
      final file = File('${dir.path}/$id.json');
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return Map<String, dynamic>.from(jsonDecode(content) as Map);
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return null;
    }
  }

  /// Delete a backup by id.
  Future<void> deleteBackup(String id) async {
    try {
      final dir = await _getBackupDir();
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
      _backups.removeWhere((b) => b.id == id);
      await _saveMeta();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting backup: $e');
    }
  }

  /// Toggle auto-backup on/off.
  Future<void> toggleAutoBackup() async {
    _autoBackupEnabled = !_autoBackupEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, _autoBackupEnabled);
    notifyListeners();
  }

  /// Run an auto-backup if enabled.  Call this on app launch or periodically.
  /// [data] should be the full app state to back up.
  Future<void> runAutoBackup(Map<String, dynamic> data) async {
    if (!_autoBackupEnabled) return;

    // Only create a new auto-backup if the last one is > 24 h old.
    final lastAuto = _backups.firstWhere(
      (b) => b.isAutoBackup,
      orElse: () => BackupInfo(
        id: '',
        timestamp: DateTime(2000),
      ),
    );
    if (DateTime.now().difference(lastAuto.timestamp).inHours < 24) return;

    await createBackup(data, auto: true);
  }
}
