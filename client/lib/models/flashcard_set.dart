import 'flashcard.dart';

class FlashcardSet {
  final String id;
  final String title;
  final String description;
  final bool isDraft;
  final double rating;
  final int ratingCount;
  final List<Flashcard> flashcards;
  final DateTime lastUpdated;
  
  FlashcardSet({
    required this.id,
    required this.title,
    this.description = '',
    this.isDraft = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.flashcards,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  FlashcardSet copyWith({
    String? title,
    String? description,
    bool? isDraft,
    double? rating,
    int? ratingCount,
    List<Flashcard>? flashcards,
    DateTime? lastUpdated,
  }) {
    return FlashcardSet(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDraft: isDraft ?? this.isDraft,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      flashcards: flashcards ?? List<Flashcard>.from(this.flashcards), // DEEP COPY
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
  
  int get termCount => flashcards.length;
  
  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      isDraft: json['isDraft'] ?? false,
      rating: json['rating'] ?? 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      flashcards: (json['flashcards'] as List)
          .map((card) => Flashcard.fromJson(card))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDraft': isDraft,
      'rating': rating,
      'ratingCount': ratingCount,
      'flashcards': flashcards.map((card) => card.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
