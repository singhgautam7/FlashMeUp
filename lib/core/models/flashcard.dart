import 'package:uuid/uuid.dart';

class Flashcard {
  final String id;
  final String collectionId;
  final String title;
  final String content; // Markdown
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    String? id,
    required this.collectionId,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Flashcard copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id,
      collectionId: collectionId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collectionId': collectionId,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      collectionId: json['collectionId'] as String,
      title: json['title'] as String,
      content: (json['content'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
