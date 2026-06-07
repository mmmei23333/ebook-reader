import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppSettings {
  final String language;
  final String comicPreset;
  final String comicReadingDirection;
  final String epubCustomLayout;
  final bool epubIgnoreFontSizes;
  final bool autoResumeLastReading;
  final bool vibrationFeedback;
  final bool autoHideHomeIndicator;
  final bool hideProAfterPurchase;
  final ThemeMode appearanceMode; // system / light / dark
  final String navigationMode;
  final int currentThemeIndex;
  final String interfaceFont;
  final String bookshelfCover;
  final bool bookshelfEffects;
  final bool coverSpineEffect;
  final bool bookOpenAnimation;
  final bool showReadingDuration;
  final bool hideBookReadingStatus;
  final int maxChapterWordCount;

  AppSettings({
    this.language = 'zh',
    this.comicPreset = 'standard',
    this.comicReadingDirection = 'rtl',
    this.epubCustomLayout = 'default',
    this.epubIgnoreFontSizes = false,
    this.autoResumeLastReading = true,
    this.vibrationFeedback = true,
    this.autoHideHomeIndicator = true,
    this.hideProAfterPurchase = false,
    this.appearanceMode = ThemeMode.system,
    this.navigationMode = 'tab',
    this.currentThemeIndex = 0,
    this.interfaceFont = 'system',
    this.bookshelfCover = 'cover',
    this.bookshelfEffects = true,
    this.coverSpineEffect = true,
    this.bookOpenAnimation = true,
    this.showReadingDuration = true,
    this.hideBookReadingStatus = false,
    this.maxChapterWordCount = 50000,
  });

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'comicPreset': comicPreset,
      'comicReadingDirection': comicReadingDirection,
      'epubCustomLayout': epubCustomLayout,
      'epubIgnoreFontSizes': epubIgnoreFontSizes,
      'autoResumeLastReading': autoResumeLastReading,
      'vibrationFeedback': vibrationFeedback,
      'autoHideHomeIndicator': autoHideHomeIndicator,
      'hideProAfterPurchase': hideProAfterPurchase,
      'appearanceMode': appearanceMode.index, // 0=system,1=light,2=dark
      'navigationMode': navigationMode,
      'currentThemeIndex': currentThemeIndex,
      'interfaceFont': interfaceFont,
      'bookshelfCover': bookshelfCover,
      'bookshelfEffects': bookshelfEffects,
      'coverSpineEffect': coverSpineEffect,
      'bookOpenAnimation': bookOpenAnimation,
      'showReadingDuration': showReadingDuration,
      'hideBookReadingStatus': hideBookReadingStatus,
      'maxChapterWordCount': maxChapterWordCount,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      language: map['language'] ?? 'zh',
      comicPreset: map['comicPreset'] ?? 'standard',
      comicReadingDirection: map['comicReadingDirection'] ?? 'rtl',
      epubCustomLayout: map['epubCustomLayout'] ?? 'default',
      epubIgnoreFontSizes: map['epubIgnoreFontSizes'] ?? false,
      autoResumeLastReading: map['autoResumeLastReading'] ?? true,
      vibrationFeedback: map['vibrationFeedback'] ?? true,
      autoHideHomeIndicator: map['autoHideHomeIndicator'] ?? true,
      hideProAfterPurchase: map['hideProAfterPurchase'] ?? false,
      appearanceMode: ThemeMode.values[map['appearanceMode'] ?? 0],
      navigationMode: map['navigationMode'] ?? 'tab',
      currentThemeIndex: map['currentThemeIndex'] ?? 0,
      interfaceFont: map['interfaceFont'] ?? 'system',
      bookshelfCover: map['bookshelfCover'] ?? 'cover',
      bookshelfEffects: map['bookshelfEffects'] ?? true,
      coverSpineEffect: map['coverSpineEffect'] ?? true,
      bookOpenAnimation: map['bookOpenAnimation'] ?? true,
      showReadingDuration: map['showReadingDuration'] ?? true,
      hideBookReadingStatus: map['hideBookReadingStatus'] ?? false,
      maxChapterWordCount: map['maxChapterWordCount'] ?? 50000,
    );
  }

  AppSettings copyWith({
    String? language,
    String? comicPreset,
    String? comicReadingDirection,
    String? epubCustomLayout,
    bool? epubIgnoreFontSizes,
    bool? autoResumeLastReading,
    bool? vibrationFeedback,
    bool? autoHideHomeIndicator,
    bool? hideProAfterPurchase,
    ThemeMode? appearanceMode,
    String? navigationMode,
    int? currentThemeIndex,
    String? interfaceFont,
    String? bookshelfCover,
    bool? bookshelfEffects,
    bool? coverSpineEffect,
    bool? bookOpenAnimation,
    bool? showReadingDuration,
    bool? hideBookReadingStatus,
    int? maxChapterWordCount,
  }) {
    return AppSettings(
      language: language ?? this.language,
      comicPreset: comicPreset ?? this.comicPreset,
      comicReadingDirection: comicReadingDirection ?? this.comicReadingDirection,
      epubCustomLayout: epubCustomLayout ?? this.epubCustomLayout,
      epubIgnoreFontSizes: epubIgnoreFontSizes ?? this.epubIgnoreFontSizes,
      autoResumeLastReading: autoResumeLastReading ?? this.autoResumeLastReading,
      vibrationFeedback: vibrationFeedback ?? this.vibrationFeedback,
      autoHideHomeIndicator: autoHideHomeIndicator ?? this.autoHideHomeIndicator,
      hideProAfterPurchase: hideProAfterPurchase ?? this.hideProAfterPurchase,
      appearanceMode: appearanceMode ?? this.appearanceMode,
      navigationMode: navigationMode ?? this.navigationMode,
      currentThemeIndex: currentThemeIndex ?? this.currentThemeIndex,
      interfaceFont: interfaceFont ?? this.interfaceFont,
      bookshelfCover: bookshelfCover ?? this.bookshelfCover,
      bookshelfEffects: bookshelfEffects ?? this.bookshelfEffects,
      coverSpineEffect: coverSpineEffect ?? this.coverSpineEffect,
      bookOpenAnimation: bookOpenAnimation ?? this.bookOpenAnimation,
      showReadingDuration: showReadingDuration ?? this.showReadingDuration,
      hideBookReadingStatus: hideBookReadingStatus ?? this.hideBookReadingStatus,
      maxChapterWordCount: maxChapterWordCount ?? this.maxChapterWordCount,
    );
  }

  static const String _prefsKey = 'app_settings';

  static Future<AppSettings> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr == null) return AppSettings();
    try {
      final map = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
      return AppSettings.fromMap(map);
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(toMap()));
  }
}
