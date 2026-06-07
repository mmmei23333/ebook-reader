class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int fileSize;
  final bool isAutoBackup;

  BackupInfo({
    required this.id,
    required this.timestamp,
    this.fileSize = 0,
    this.isAutoBackup = false,
  });

  /// Human-readable file size string (e.g. "1.2 MB").
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'fileSize': fileSize,
      'isAutoBackup': isAutoBackup,
    };
  }

  factory BackupInfo.fromMap(Map<String, dynamic> map) {
    return BackupInfo(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      fileSize: map['fileSize'] ?? 0,
      isAutoBackup: map['isAutoBackup'] ?? false,
    );
  }

  BackupInfo copyWith({
    String? id,
    DateTime? timestamp,
    int? fileSize,
    bool? isAutoBackup,
  }) {
    return BackupInfo(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      fileSize: fileSize ?? this.fileSize,
      isAutoBackup: isAutoBackup ?? this.isAutoBackup,
    );
  }
}
