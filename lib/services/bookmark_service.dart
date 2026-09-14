import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists bookmarked stories locally (SharedPreferences) and exposes a
/// [ValueListenable] so any screen (story detail, profile, bookmarks list)
/// stays in sync the moment a bookmark is toggled anywhere in the app.
class BookmarkService {
  BookmarkService._();
  static final BookmarkService instance = BookmarkService._();

  static const String _storageKey = 'bookmarked_stories_v1';

  final ValueNotifier<List<Map<String, dynamic>>> bookmarks =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        bookmarks.value = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        bookmarks.value = [];
      }
    }
    _loaded = true;
  }

  Future<void> init() => _ensureLoaded();

  bool isBookmarked(String storyId) {
    return bookmarks.value.any((s) => s['id'] == storyId);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(bookmarks.value));
  }

  /// Adds the story if not already bookmarked, removes it otherwise.
  /// Returns the new bookmarked state.
  Future<bool> toggle(Map<String, dynamic> story) async {
    await _ensureLoaded();
    final id = story['id'];
    final current = List<Map<String, dynamic>>.from(bookmarks.value);
    final existingIndex = current.indexWhere((s) => s['id'] == id);
    bool nowBookmarked;
    if (existingIndex >= 0) {
      current.removeAt(existingIndex);
      nowBookmarked = false;
    } else {
      current.insert(0, story);
      nowBookmarked = true;
    }
    bookmarks.value = current;
    await _persist();
    return nowBookmarked;
  }

  Future<void> remove(String storyId) async {
    await _ensureLoaded();
    final current = List<Map<String, dynamic>>.from(bookmarks.value)
      ..removeWhere((s) => s['id'] == storyId);
    bookmarks.value = current;
    await _persist();
  }
}
