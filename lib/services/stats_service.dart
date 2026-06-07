import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_stats.dart';

class StatsService extends ChangeNotifier {
  Map<String, ReadingStats> _dailyStats = {};
  List<ReadingSession> _todaySessions = [];
  ReadingGoal _goal = ReadingGoal();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  ReadingGoal get goal => _goal;

  StatsService() {
    _load();
  }

  // ---- persistence -------------------------------------------------------

  static const _statsKey = 'reading_stats';
  static const _sessionsKey = 'reading_sessions_today';
  static const _goalKey = 'reading_goal';

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();

      // Daily stats map  (key = "YYYY-MM-DD", value = JSON)
      final statsJson = prefs.getString(_statsKey);
      if (statsJson != null) {
        final Map<String, dynamic> decoded =
            Map<String, dynamic>.from(jsonDecode(statsJson) as Map);
        _dailyStats = decoded.map(
          (k, v) => MapEntry(k, ReadingStats.fromMap(
            Map<String, dynamic>.from(v as Map),
          )),
        );
      }

      // Today's sessions
      final sessJson = prefs.getString(_sessionsKey);
      if (sessJson != null) {
        final list = jsonDecode(sessJson) as List;
        final todayKey = ReadingStats.dateKey(DateTime.now());
        // Only load if they belong to today
        final storedDate = prefs.getString('${_sessionsKey}_date');
        if (storedDate == todayKey) {
          _todaySessions = list
              .map((e) => ReadingSession.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList();
        } else {
          _todaySessions = [];
        }
      }

      // Goal
      final goalJson = prefs.getString(_goalKey);
      if (goalJson != null) {
        _goal = ReadingGoal.fromMap(
            Map<String, dynamic>.from(jsonDecode(goalJson) as Map));
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          _dailyStats.map((k, v) => MapEntry(k, v.toMap()));
      await prefs.setString(_statsKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving stats: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionsKey,
        jsonEncode(_todaySessions.map((s) => s.toMap()).toList()),
      );
      await prefs.setString(
        '${_sessionsKey}_date',
        ReadingStats.dateKey(DateTime.now()),
      );
    } catch (e) {
      debugPrint('Error saving sessions: $e');
    }
  }

  Future<void> _saveGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_goalKey, jsonEncode(_goal.toMap()));
    } catch (e) {
      debugPrint('Error saving goal: $e');
    }
  }

  // ---- public API --------------------------------------------------------

  /// Record a completed reading session.
  Future<void> recordReadingSession(
      DateTime start, DateTime end) async {
    final session = ReadingSession(startTime: start, endTime: end);
    _todaySessions.add(session);
    await _saveSessions();

    final key = ReadingStats.dateKey(start);
    final existing = _dailyStats[key];
    final minutes = session.durationInMinutes;

    _dailyStats[key] = (existing ?? ReadingStats(date: start)).copyWith(
      totalMinutes: (existing?.totalMinutes ?? 0) + minutes,
      readingSessions: (existing?.readingSessions ?? 0) + 1,
    );

    await _saveStats();
    notifyListeners();
  }

  /// Update book counts for a given date key.
  Future<void> updateBookCounts({
    required String dateKey,
    int? booksReading,
    int? booksCompleted,
    int? notesCount,
  }) async {
    final existing = _dailyStats[dateKey];
    final date = existing?.date ?? DateTime.now();
    _dailyStats[dateKey] = (existing ?? ReadingStats(date: date)).copyWith(
      booksReading: booksReading,
      booksCompleted: booksCompleted,
      notesCount: notesCount,
    );
    await _saveStats();
    notifyListeners();
  }

  /// Get stats for a single date.
  ReadingStats getStatsForDate(DateTime date) {
    final key = ReadingStats.dateKey(date);
    return _dailyStats[key] ?? ReadingStats(date: date);
  }

  /// Get aggregated stats for a range.
  /// [period] is one of: day, week, month, year, total.
  ReadingStats getStatsForRange(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'day':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'total':
      default:
        startDate = DateTime(2000);
        break;
    }

    var totalMinutes = 0;
    var sessions = 0;
    var maxReading = 0;
    var maxCompleted = 0;
    var maxNotes = 0;

    for (final entry in _dailyStats.entries) {
      final stat = entry.value;
      if (!stat.date.isBefore(startDate)) {
        totalMinutes += stat.totalMinutes;
        sessions += stat.readingSessions;
        if (stat.booksReading > maxReading) maxReading = stat.booksReading;
        if (stat.booksCompleted > maxCompleted) {
          maxCompleted = stat.booksCompleted;
        }
        if (stat.notesCount > maxNotes) maxNotes = stat.notesCount;
      }
    }

    return ReadingStats(
      date: now,
      totalMinutes: totalMinutes,
      booksReading: maxReading,
      booksCompleted: maxCompleted,
      readingSessions: sessions,
      notesCount: maxNotes,
    );
  }

  /// Set the daily reading goal.
  Future<void> setDailyGoal(int minutes) async {
    _goal = _goal.copyWith(dailyMinutesGoal: minutes);
    await _saveGoal();
    notifyListeners();
  }

  /// Toggle reminder for daily goal.
  Future<void> toggleReminder() async {
    _goal = _goal.copyWith(reminderEnabled: !_goal.reminderEnabled);
    await _saveGoal();
    notifyListeners();
  }

  /// Get today's progress as a fraction 0.0–1.0 (capped at 1.0).
  double getTodayProgress() {
    final todayStats = getStatsForDate(DateTime.now());
    if (_goal.dailyMinutesGoal <= 0) return 0.0;
    return (todayStats.totalMinutes / _goal.dailyMinutesGoal)
        .clamp(0.0, 1.0);
  }

  /// Get today's total reading minutes.
  int get todayMinutes => getStatsForDate(DateTime.now()).totalMinutes;
  /// Get total reading minutes across all time.
  int get totalReadingMinutes => getStatsForRange('total').totalMinutes;

  /// Get today's session count.
  int get todaySessionCount => _todaySessions.length;

  /// All sessions recorded today.
  List<ReadingSession> get todaySessions =>
      List.unmodifiable(_todaySessions);
}
