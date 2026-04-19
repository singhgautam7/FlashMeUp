import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class FlashcardCollection {
  final String id;
  final String title;
  final String? description;
  final int iconCodePoint;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardCollection({
    String? id,
    required this.title,
    this.description,
    int? iconCodePoint,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        iconCodePoint =
            iconCodePoint ?? Icons.auto_stories_rounded.codePoint,
        colorValue = colorValue ?? 0xFF6366F1,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();


  IconData get iconData => getCollectionIconData(iconCodePoint);
  Color get color => Color(colorValue);

  FlashcardCollection copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    int? iconCodePoint,
    int? colorValue,
    DateTime? updatedAt,
  }) {
    return FlashcardCollection(
      id: id,
      title: title ?? this.title,
      description:
          clearDescription ? null : (description ?? this.description),
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FlashcardCollection.fromJson(Map<String, dynamic> json) {
    return FlashcardCollection(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      iconCodePoint: (json['iconCodePoint'] as int?) ??
          Icons.auto_stories_rounded.codePoint,
      colorValue: (json['colorValue'] as int?) ?? 0xFF6366F1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

const List<IconData> kCollectionIcons = [
  Icons.auto_stories_rounded,
  Icons.library_books_rounded,
  Icons.school_rounded,
  Icons.psychology_rounded,
  Icons.science_rounded,
  Icons.biotech_rounded,
  Icons.calculate_rounded,
  Icons.functions_rounded,
  Icons.language_rounded,
  Icons.translate_rounded,
  Icons.spellcheck_rounded,
  Icons.history_edu_rounded,
  Icons.public_rounded,
  Icons.map_rounded,
  Icons.palette_rounded,
  Icons.music_note_rounded,
  Icons.theater_comedy_rounded,
  Icons.brush_rounded,
  Icons.camera_alt_rounded,
  Icons.computer_rounded,
  Icons.code_rounded,
  Icons.memory_rounded,
  Icons.developer_mode_rounded,
  Icons.fitness_center_rounded,
  Icons.restaurant_rounded,
  Icons.travel_explore_rounded,
  Icons.sports_soccer_rounded,
  Icons.local_hospital_rounded,
  Icons.medical_services_rounded,
  Icons.eco_rounded,
  Icons.business_rounded,
  Icons.account_balance_rounded,
  Icons.gavel_rounded,
  Icons.lightbulb_rounded,
  Icons.bolt_rounded,
  Icons.star_rounded,
  Icons.favorite_rounded,
  Icons.emoji_events_rounded,
  Icons.rocket_launch_rounded,
  Icons.book_rounded,
];

IconData getCollectionIconData(int codePoint) {
  for (final icon in kCollectionIcons) {
    if (icon.codePoint == codePoint) return icon;
  }
  return Icons.auto_stories_rounded; // fallback
}
