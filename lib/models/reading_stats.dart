class ReadingSession {
  final DateTime startTime;
  final DateTime endTime;

  ReadingSession({
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  int get durationInMinutes => duration.inMinutes;

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    return ReadingSession(
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
    );
  }

  ReadingSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return ReadingSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

class ReadingGoal {
  final int dailyMinutesGoal;
  final bool reminderEnabled;

  ReadingGoal({
    this.dailyMinutesGoal = 30,
    this.reminderEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyMinutesGoal': dailyMinutesGoal,
      'reminderEnabled': reminderEnabled,
    };
  }

  factory ReadingGoal.fromMap(Map<String, dynamic> map) {
    return ReadingGoal(
      dailyMinutesGoal: map['dailyMinutesGoal'] ?? 30,
      reminderEnabled: map['reminderEnabled'] ?? false,
    );
  }

  ReadingGoal copyWith({
    int? dailyMinutesGoal,
    bool? reminderEnabled,
  }) {
    return ReadingGoal(
      dailyMinutesGoal: dailyMinutesGoal ?? this.dailyMinutesGoal,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }
}

class ReadingStats {
  final DateTime date;
  final int totalMinutes;
  final int booksReading;
  final int booksCompleted;
  final int readingSessions;
  final int notesCount;

  ReadingStats({
    required this.date,
    this.totalMinutes = 0,
    this.booksReading = 0,
    this.booksCompleted = 0,
    this.readingSessions = 0,
    this.notesCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'totalMinutes': totalMinutes,
      'booksReading': booksReading,
      'booksCompleted': booksCompleted,
      'readingSessions': readingSessions,
      'notesCount': notesCount,
    };
  }

  factory ReadingStats.fromMap(Map<String, dynamic> map) {
    return ReadingStats(
      date: DateTime.parse(map['date']),
      totalMinutes: map['totalMinutes'] ?? 0,
      booksReading: map['booksReading'] ?? 0,
      booksCompleted: map['booksCompleted'] ?? 0,
      readingSessions: map['readingSessions'] ?? 0,
      notesCount: map['notesCount'] ?? 0,
    );
  }

  ReadingStats copyWith({
    DateTime? date,
    int? totalMinutes,
    int? booksReading,
    int? booksCompleted,
    int? readingSessions,
    int? notesCount,
  }) {
    return ReadingStats(
      date: date ?? this.date,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      booksReading: booksReading ?? this.booksReading,
      booksCompleted: booksCompleted ?? this.booksCompleted,
      readingSessions: readingSessions ?? this.readingSessions,
      notesCount: notesCount ?? this.notesCount,
    );
  }

  /// Helper: get a date-only key string (YYYY-MM-DD) for grouping stats by day.
  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
