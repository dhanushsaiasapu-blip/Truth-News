import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global language state notifier — shared across the whole app.
/// Use [LanguageNotifier.instance] to access the singleton.
class LanguageNotifier extends ValueNotifier<String> {
  static final LanguageNotifier _instance = LanguageNotifier._internal();
  static LanguageNotifier get instance => _instance;

  LanguageNotifier._internal() : super('English');

  static const String _languageKey = 'selected_language';

  /// Load persisted language on app start.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_languageKey) ?? 'English';
  }

  /// Persist and broadcast a new language selection.
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    value = language;
  }
}
