import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  SettingsService() {
    _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await AppSettings.loadFromPrefs();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _settings.saveToPrefs();
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // --- Language ---

  Future<void> updateLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _save();
    notifyListeners();
  }

  // --- Appearance ---

  Future<void> updateAppearanceMode(ThemeMode mode) async {
    _settings = _settings.copyWith(appearanceMode: mode);
    await _save();
    notifyListeners();
  }

  Future<void> updateTheme(int index) async {
    _settings = _settings.copyWith(currentThemeIndex: index);
    await _save();
    notifyListeners();
  }

  Future<void> updateInterfaceFont(String font) async {
    _settings = _settings.copyWith(interfaceFont: font);
    await _save();
    notifyListeners();
  }

  // --- Comic settings ---

  Future<void> updateComicPreset(String preset) async {
    _settings = _settings.copyWith(comicPreset: preset);
    await _save();
    notifyListeners();
  }

  Future<void> updateComicReadingDirection(String direction) async {
    _settings = _settings.copyWith(comicReadingDirection: direction);
    await _save();
    notifyListeners();
  }

  // --- EPUB settings ---

  Future<void> updateEpubCustomLayout(String layout) async {
    _settings = _settings.copyWith(epubCustomLayout: layout);
    await _save();
    notifyListeners();
  }

  Future<void> toggleEpubIgnoreFontSizes() async {
    _settings = _settings.copyWith(
      epubIgnoreFontSizes: !_settings.epubIgnoreFontSizes,
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateMaxChapterWordCount(int count) async {
    _settings = _settings.copyWith(maxChapterWordCount: count);
    await _save();
    notifyListeners();
  }

  // --- Behaviour toggles ---

  Future<void> toggleAutoResumeLastReading() async {
    _settings = _settings.copyWith(
      autoResumeLastReading: !_settings.autoResumeLastReading,
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _settings = _settings.copyWith(
      vibrationFeedback: !_settings.vibrationFeedback,
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleAutoHideHomeIndicator() async {
    _settings = _settings.copyWith(
      autoHideHomeIndicator: !_settings.autoHideHomeIndicator,
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleHideProAfterPurchase() async {
    _settings = _settings.copyWith(
      hideProAfterPurchase: !_settings.hideProAfterPurchase,
    );
    await _save();
    notifyListeners();
  }

  // --- Navigation ---

  Future<void> updateNavigationMode(String mode) async {
    _settings = _settings.copyWith(navigationMode: mode);
    await _save();
    notifyListeners();
  }

  // --- Bookshelf ---

  Future<void> updateBookshelfCover(String cover) async {
    _settings = _settings.copyWith(bookshelfCover: cover);
    await _save();
    notifyListeners();
  }

  Future<void> toggleBookshelfEffects() async {
    _settings = _settings.copyWith(
      bookshelfEffects: !_settings.bookshelfEffects,
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleCoverSpineEffect() async {
    _settings = _settings.copyWith(
      coverSpineEffect: !_settings.coverSpineEffect,
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleBookOpenAnimation() async {
    _settings = _settings.copyWith(
      bookOpenAnimation: !_settings.bookOpenAnimation,
    );
    await _save();
    notifyListeners();
  }

  // --- Reading display ---

  Future<void> toggleShowReadingDuration() async {
    _settings = _settings.copyWith(
      showReadingDuration: !_settings.showReadingDuration,
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleHideBookReadingStatus() async {
    _settings = _settings.copyWith(
      hideBookReadingStatus: !_settings.hideBookReadingStatus,
    );
    await _save();
    notifyListeners();
  }

  // --- Bulk update ---

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _save();
    notifyListeners();
  }
}
