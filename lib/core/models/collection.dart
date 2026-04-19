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

  IconData get iconData =>
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');
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
