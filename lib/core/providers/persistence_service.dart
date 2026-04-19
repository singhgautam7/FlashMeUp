import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/collection.dart';
import '../models/flashcard.dart';

/// Handles local persistence using SharedPreferences (JSON strings).
class PersistenceService {
  static const _collectionsKey = 'fmu_collections_v1';
  static const _flashcardsKey = 'fmu_flashcards_v1';

  // ── Collections ───────────────────────────────
  static Future<void> saveCollections(
      List<FlashcardCollection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    final json =
        jsonEncode(collections.map((c) => c.toJson()).toList());
    await prefs.setString(_collectionsKey, json);
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
    final json =
        jsonEncode(flashcards.map((f) => f.toJson()).toList());
    await prefs.setString(_flashcardsKey, json);
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

  // ── Clear ─────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_collectionsKey);
    await prefs.remove(_flashcardsKey);
  }
}
