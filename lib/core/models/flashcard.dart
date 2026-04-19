import 'package:uuid/uuid.dart';

class Flashcard {
  final String id;
  final String collectionId;
  final String title;
  final String content; // Markdown
  final List<String> tagIds;
  final int timesReviewed;
  final int correctCount;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Flashcard({
    String? id,
    required this.collectionId,
    required this.title,
    this.content = '',
    List<String>? tagIds,
    this.timesReviewed = 0,
    this.correctCount = 0,
    this.lastReviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        tagIds = tagIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Flashcard copyWith({
    String? title,
    String? content,
    List<String>? tagIds,
    int? timesReviewed,
    int? correctCount,
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id,
      collectionId: collectionId,
      title: title ?? this.title,
      content: content ?? this.content,
      tagIds: tagIds ?? this.tagIds,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      correctCount: correctCount ?? this.correctCount,
      lastReviewedAt:
          clearLastReviewedAt ? null : (lastReviewedAt ?? this.lastReviewedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collectionId': collectionId,
        'title': title,
        'content': content,
        'tagIds': tagIds,
        'timesReviewed': timesReviewed,
        'correctCount': correctCount,
        'lastReviewedAt': lastReviewedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      collectionId: json['collectionId'] as String,
      title: json['title'] as String,
      content: (json['content'] as String?) ?? '',
      tagIds: (json['tagIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      timesReviewed: (json['timesReviewed'] as int?) ?? 0,
      correctCount: (json['correctCount'] as int?) ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
