import 'flashcard.dart';

class FlashcardSet {
  final String id;
  final String title;
  final String description;
  final bool isDraft;
  final bool isPublic;
  final double rating;
  final int ratingCount;
  final List<Flashcard> flashcards;
  final DateTime lastUpdated;
  final String? ownerId;
  final bool isOwned;
  
  FlashcardSet({
    required this.id,
    required this.title,
    this.description = '',
    this.isDraft = false,
    this.isPublic = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.flashcards,
    DateTime? lastUpdated,
    this.ownerId,
    this.isOwned = true,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
  
  FlashcardSet copyWith({
    String? title,
    String? description,
    bool? isDraft,
    bool? isPublic,
    double? rating,
    int? ratingCount,
    List<Flashcard>? flashcards,
    DateTime? lastUpdated,
    String? ownerId,
    bool? isOwned,
  }) {
    return FlashcardSet(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDraft: isDraft ?? this.isDraft,
      isPublic: isPublic ?? this.isPublic,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      flashcards: flashcards ?? this.flashcards,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      ownerId: ownerId ?? this.ownerId,
      isOwned: isOwned ?? this.isOwned,
    );
  }
  
  int get termCount => flashcards.length;
  
  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      isDraft: json['isDraft'] ?? false,
      isPublic: json['isPublic'] ?? false,
      rating: json['rating'] ?? 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      flashcards: (json['flashcards'] as List)
          .map((card) => Flashcard.fromJson(card))
          .toList(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
      ownerId: json['ownerId'],
      isOwned: json['isOwned'] ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDraft': isDraft,
      'isPublic': isPublic,
      'rating': rating,
      'ratingCount': ratingCount,
      'flashcards': flashcards.map((card) => card.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'ownerId': ownerId,
      'isOwned': isOwned,
    };
  }
}
