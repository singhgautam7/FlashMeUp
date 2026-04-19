import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/collection.dart';
import '../models/flashcard.dart';
import 'persistence_service.dart';

// ─────────────────────────────────────────────
// Theme Mode
// ─────────────────────────────────────────────
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
        (ref) => ThemeModeNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);
  void setMode(ThemeMode mode) => state = mode;
}

// ─────────────────────────────────────────────
// Nav bar visibility
// ─────────────────────────────────────────────
final showNavBarProvider = StateProvider<bool>((ref) => true);

// ─────────────────────────────────────────────
// Collections
// ─────────────────────────────────────────────
final collectionsProvider =
    StateNotifierProvider<CollectionsNotifier, List<FlashcardCollection>>(
        (ref) => CollectionsNotifier());

class CollectionsNotifier
    extends StateNotifier<List<FlashcardCollection>> {
  CollectionsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final data = await PersistenceService.loadCollections();
    if (mounted) state = data;
  }

  void add(FlashcardCollection c) {
    state = [...state, c];
    PersistenceService.saveCollections(state);
  }

  void update(FlashcardCollection c) {
    state = state.map((e) => e.id == c.id ? c : e).toList();
    PersistenceService.saveCollections(state);
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    PersistenceService.saveCollections(state);
  }

  void replaceAll(List<FlashcardCollection> collections) {
    state = collections;
    PersistenceService.saveCollections(state);
  }

  void clear() {
    state = [];
    PersistenceService.saveCollections(state);
  }
}

// ─────────────────────────────────────────────
// Flashcards
// ─────────────────────────────────────────────
final flashcardsProvider =
    StateNotifierProvider<FlashcardsNotifier, List<Flashcard>>(
        (ref) => FlashcardsNotifier());

class FlashcardsNotifier extends StateNotifier<List<Flashcard>> {
  FlashcardsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final data = await PersistenceService.loadFlashcards();
    if (mounted) state = data;
  }

  void add(Flashcard f) {
    state = [...state, f];
    PersistenceService.saveFlashcards(state);
  }

  void update(Flashcard f) {
    state = state.map((e) => e.id == f.id ? f : e).toList();
    PersistenceService.saveFlashcards(state);
  }

  void delete(String id) {
    state = state.where((e) => e.id != id).toList();
    PersistenceService.saveFlashcards(state);
  }

  void deleteByCollection(String collectionId) {
    state = state.where((f) => f.collectionId != collectionId).toList();
    PersistenceService.saveFlashcards(state);
  }

  void replaceAll(List<Flashcard> flashcards) {
    state = flashcards;
    PersistenceService.saveFlashcards(state);
  }

  void clear() {
    state = [];
    PersistenceService.saveFlashcards(state);
  }
}

// ─────────────────────────────────────────────
// Derived: cards for a collection
// ─────────────────────────────────────────────
final collectionFlashcardsProvider =
    Provider.family<List<Flashcard>, String>((ref, collectionId) {
  return ref
      .watch(flashcardsProvider)
      .where((f) => f.collectionId == collectionId)
      .toList();
});

// ─────────────────────────────────────────────
// Mock Data Generator
// ─────────────────────────────────────────────
void generateMockData(WidgetRef ref) {
  final cols = <FlashcardCollection>[];
  final cards = <Flashcard>[];

  // ── Vocabulary Essentials ──────────────────
  final vocab = FlashcardCollection(
    title: 'Vocabulary Essentials',
    description:
        'Expand your English vocabulary with essential words and definitions.',
    iconCodePoint: Icons.translate_rounded.codePoint,
    colorValue: 0xFF8B5CF6,
  );
  cols.add(vocab);
  cards.addAll([
    Flashcard(
      collectionId: vocab.id,
      title: 'Ephemeral',
      content:
          '**Ephemeral** *(adjective)*\n\nLasting for a very short time.\n\n> *Example:* The ephemeral beauty of cherry blossoms lasts only a week.',
    ),
    Flashcard(
      collectionId: vocab.id,
      title: 'Serendipity',
      content:
          '**Serendipity** *(noun)*\n\nThe occurrence of events by chance in a happy or beneficial way.\n\n> *Example:* By serendipity, she found the perfect apartment.',
    ),
    Flashcard(
      collectionId: vocab.id,
      title: 'Melancholy',
      content:
          '**Melancholy** *(noun / adjective)*\n\nA feeling of pensive sadness with no obvious cause.\n\n> *Example:* The grey skies brought a sense of melancholy.',
    ),
    Flashcard(
      collectionId: vocab.id,
      title: 'Resilience',
      content:
          '**Resilience** *(noun)*\n\nThe capacity to recover quickly from difficulties.\n\n> *Example:* Her resilience in the face of adversity inspired everyone.',
    ),
    Flashcard(
      collectionId: vocab.id,
      title: 'Eloquent',
      content:
          '**Eloquent** *(adjective)*\n\nFluent or persuasive in speaking or writing.\n\n> *Example:* The politician gave an eloquent speech about climate change.',
    ),
  ]);

  // ── Neuroanatomy Fundamentals ──────────────
  final neuro = FlashcardCollection(
    title: 'Neuroanatomy Fundamentals',
    description:
        'Core neuroanatomy concepts for medical and neuroscience students.',
    iconCodePoint: Icons.psychology_rounded.codePoint,
    colorValue: 0xFFEF4444,
  );
  cols.add(neuro);
  cards.addAll([
    Flashcard(
      collectionId: neuro.id,
      title: 'Superior Colliculus',
      content:
          '**Superior Colliculus**\n\nPrimary relay center for visual information in the midbrain.\n\n**Functions:**\n- Visual orienting\n- Eye movement control\n- Multisensory integration',
    ),
    Flashcard(
      collectionId: neuro.id,
      title: "Broca's Area",
      content:
          "**Broca's Area**\n\nLocated in the frontal lobe (Brodmann areas 44 & 45).\n\n**Function:** Speech production and language processing.\n\n**Damage causes:** Broca's aphasia — difficulty producing speech, comprehension largely intact.",
    ),
    Flashcard(
      collectionId: neuro.id,
      title: 'Myelin Sheath',
      content:
          '**Myelin Sheath**\n\nInsulating layer formed by:\n- **Oligodendrocytes** in the CNS\n- **Schwann cells** in the PNS\n\n**Purpose:** Increases nerve conduction velocity via saltatory conduction.',
    ),
  ]);

  // ── Spanish Basics ─────────────────────────
  final spanish = FlashcardCollection(
    title: 'Spanish Basics',
    description:
        'Essential Spanish phrases and vocabulary for absolute beginners.',
    iconCodePoint: Icons.language_rounded.codePoint,
    colorValue: 0xFFF97316,
  );
  cols.add(spanish);
  cards.addAll([
    Flashcard(
      collectionId: spanish.id,
      title: 'Hola',
      content:
          '**Hola** — Hello\n\n*Pronunciation:* OH-lah\n\nUniversal greeting in Spanish-speaking countries.',
    ),
    Flashcard(
      collectionId: spanish.id,
      title: 'Gracias',
      content:
          '**Gracias** — Thank you\n\n*Pronunciation:* GRAH-syahs\n\n*Response:* **De nada** (You\'re welcome)',
    ),
    Flashcard(
      collectionId: spanish.id,
      title: 'Por favor',
      content:
          '**Por favor** — Please\n\n*Pronunciation:* por fah-VOR\n\nAlways use when making requests.',
    ),
    Flashcard(
      collectionId: spanish.id,
      title: '¿Cómo estás?',
      content:
          '**¿Cómo estás?** — How are you? *(informal)*\n\nFormal: ¿Cómo está usted?\n\n*Response:* **Bien, gracias** — Fine, thank you.',
    ),
  ]);

  ref.read(collectionsProvider.notifier).replaceAll(cols);
  ref.read(flashcardsProvider.notifier).replaceAll(cards);
}
