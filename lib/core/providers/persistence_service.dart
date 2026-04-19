import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';
import '../models/flashcard.dart';
import '../models/tag.dart';

class PersistenceService {
  static const _collectionsKey = 'fmu_collections_v1';
  static const _flashcardsKey = 'fmu_flashcards_v1';
  static const _tagsKey = 'fmu_tags_v1';
  static const _themeModeKey = 'fmu_theme_mode_v1';

  // ── Collections ───────────────────────────────
  static Future<void> saveCollections(
      List<FlashcardCollection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _collectionsKey,
        jsonEncode(collections.map((c) => c.toJson()).toList()));
  }

  static Future<List<FlashcardCollection>> loadCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_collectionsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) =>
              FlashcardCollection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Flashcards ────────────────────────────────
  static Future<void> saveFlashcards(List<Flashcard> flashcards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _flashcardsKey,
        jsonEncode(flashcards.map((f) => f.toJson()).toList()));
  }

  static Future<List<Flashcard>> loadFlashcards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_flashcardsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Tags ──────────────────────────────────────
  static Future<void> saveTags(List<Tag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _tagsKey, jsonEncode(tags.map((t) => t.toJson()).toList()));
  }

  static Future<List<Tag>> loadTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_tagsKey);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Theme Mode ────────────────────────────────
  static Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  // ── Clear ─────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collectionsKey);
    await prefs.remove(_flashcardsKey);
    await prefs.remove(_tagsKey);
    await prefs.remove(_themeModeKey);
  }
}
