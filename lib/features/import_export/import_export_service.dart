import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../../core/models/collection.dart';
import '../../core/models/flashcard.dart';
import '../../core/models/tag.dart';

class ImportExportService {
  static const _version = '1';

  static String exportToJson({
    required List<FlashcardCollection> collections,
    required List<Flashcard> flashcards,
    required List<Tag> tags,
  }) {
    final data = {
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'collections': collections.map((c) => c.toJson()).toList(),
      'flashcards': flashcards.map((f) => f.toJson()).toList(),
      'tags': tags.map((t) => t.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  static ({
    List<FlashcardCollection> collections,
    List<Flashcard> flashcards,
    List<Tag> tags,
  }) importFromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final collections = (data['collections'] as List? ?? [])
        .map((e) => FlashcardCollection.fromJson(e as Map<String, dynamic>))
        .toList();
    final flashcards = (data['flashcards'] as List? ?? [])
        .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
        .toList();
    final tags = (data['tags'] as List? ?? [])
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      collections: collections,
      flashcards: flashcards,
      tags: tags,
    );
  }

  static Future<void> exportFile({
    required List<FlashcardCollection> collections,
    required List<Flashcard> flashcards,
    required List<Tag> tags,
  }) async {
    final json = exportToJson(
        collections: collections, flashcards: flashcards, tags: tags);
    final dir = await getTemporaryDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/flashmeup_backup_$timestamp.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'FlashMeUp backup',
    );
  }

  static String templateJson() {
    final sampleCollection = FlashcardCollection(
      title: 'Sample Collection',
      description: 'A sample collection to show the import format.',
    );
    final sampleTag = Tag(name: 'sample');
    final sampleCards = [
      Flashcard(
        collectionId: sampleCollection.id,
        title: 'What is photosynthesis?',
        content:
            '**Photosynthesis** is the process by which plants convert light energy into chemical energy.\n\n> *Formula:* 6CO₂ + 6H₂O + light → C₆H₁₂O₆ + 6O₂',
        tagIds: [sampleTag.id],
      ),
      Flashcard(
        collectionId: sampleCollection.id,
        title: 'What is osmosis?',
        content:
            '**Osmosis** is the movement of water molecules from a region of lower solute concentration to a region of higher solute concentration through a semi-permeable membrane.',
        tagIds: [sampleTag.id],
      ),
    ];
    return exportToJson(
      collections: [sampleCollection],
      flashcards: sampleCards,
      tags: [sampleTag],
    );
  }

  static Future<void> shareTemplate() async {
    final json = templateJson();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/flashmeup_template.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: 'FlashMeUp import template',
    );
  }
}
