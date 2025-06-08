import 'flashcard.dart';

class FlashcardSet {
  // ===== EXISTING FIELDS (PRESERVED FOR BACKWARD COMPATIBILITY) =====
  final String id;
  final String title;
  final String description;
  final bool isDraft;
  final double rating;
  final int ratingCount;
  final List<Flashcard> flashcards;
  final DateTime lastUpdated;
  
  // ===== NEW SUPABASE FIELDS (PHASE 1 ENHANCEMENT) =====
  final String? userId;           // References auth.users(id) - null for guest users
  final String? guestSessionId;   // References guest_sessions(session_id) - null for authenticated users
  final String? categoryId;       // References categories(id) - optional category assignment
  final bool isGuestData;         // Tracks ownership type: true = guest, false = authenticated user
  final DateTime? lastStudied;    // Study tracking - when set was last studied
  final int studyStreak;          // Progress tracking - consecutive study days
  final DateTime createdAt;       // Database creation timestamp
  final DateTime updatedAt;       // Database last update timestamp
  
  FlashcardSet({
    required this.id,
    required this.title,
    this.description = '',
    this.isDraft = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.flashcards,
    DateTime? lastUpdated,
    // New Supabase fields with backward-compatible defaults
    this.userId,
    this.guestSessionId,
    this.categoryId,
    this.isGuestData = true,        // Default to guest data for backward compatibility
    this.lastStudied,
    this.studyStreak = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  FlashcardSet copyWith({
    String? title,
    String? description,
    bool? isDraft,
    double? rating,
    int? ratingCount,
    List<Flashcard>? flashcards,
    DateTime? lastUpdated,
    // New Supabase fields
    String? userId,
    String? guestSessionId,
    String? categoryId,
    bool? isGuestData,
    DateTime? lastStudied,
    int? studyStreak,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      // New Supabase fields
      userId: userId ?? this.userId,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      categoryId: categoryId ?? this.categoryId,
      isGuestData: isGuestData ?? this.isGuestData,
      lastStudied: lastStudied ?? this.lastStudied,
      studyStreak: studyStreak ?? this.studyStreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  int get termCount => flashcards.length;
  
  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      // Existing fields (unchanged for backward compatibility)
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
      // New Supabase fields with safe defaults for backward compatibility
      userId: json['userId'],  // null if not present
      guestSessionId: json['guestSessionId'],  // null if not present
      categoryId: json['categoryId'],  // null if not present
      isGuestData: json['isGuestData'] ?? true,  // Default to guest data for legacy sets
      lastStudied: json['lastStudied'] != null ? DateTime.parse(json['lastStudied']) : null,
      studyStreak: json['studyStreak'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      // Existing fields (preserved for backward compatibility)
      'id': id,
      'title': title,
      'description': description,
      'isDraft': isDraft,
      'rating': rating,
      'ratingCount': ratingCount,
      'flashcards': flashcards.map((card) => card.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      // New Supabase fields
      'userId': userId,
      'guestSessionId': guestSessionId,
      'categoryId': categoryId,
      'isGuestData': isGuestData,
      'lastStudied': lastStudied?.toIso8601String(),
      'studyStreak': studyStreak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  // ===== CONVENIENCE METHODS AND GETTERS (PHASE 1 ENHANCEMENT) =====
  
  /// Returns true if this set belongs to an authenticated user
  bool get isAuthenticatedUserData => !isGuestData && userId != null;
  
  /// Returns true if this set belongs to a guest session
  bool get isGuestUserData => isGuestData && guestSessionId != null;
  
  /// Returns the owner identifier (userId for auth users, guestSessionId for guests)
  String? get ownerId => isGuestData ? guestSessionId : userId;
  
  /// Returns true if the set has been studied recently (within 7 days)
  bool get hasRecentStudyActivity {
    if (lastStudied == null) return false;
    return DateTime.now().difference(lastStudied!).inDays <= 7;
  }
  
  /// Returns true if the set has an active study streak
  bool get hasActiveStreak => studyStreak > 0;
  
  /// Creates a copy of this set for an authenticated user
  FlashcardSet copyAsAuthenticatedUserData(String userId) {
    return copyWith(
      userId: userId,
      guestSessionId: null,
      isGuestData: false,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates a copy of this set for a guest session
  FlashcardSet copyAsGuestData(String guestSessionId) {
    return copyWith(
      userId: null,
      guestSessionId: guestSessionId,
      isGuestData: true,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates a copy with updated study tracking
  FlashcardSet copyWithStudyUpdate({int? newStreak}) {
    return copyWith(
      lastStudied: DateTime.now(),
      studyStreak: newStreak ?? studyStreak + 1,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Factory constructor for creating a new guest user set
  factory FlashcardSet.forGuest({
    required String id,
    required String title,
    required String guestSessionId,
    required List<Flashcard> flashcards,
    String description = '',
    String? categoryId,
  }) {
    final now = DateTime.now();
    return FlashcardSet(
      id: id,
      title: title,
      description: description,
      flashcards: flashcards,
      guestSessionId: guestSessionId,
      isGuestData: true,
      categoryId: categoryId,
      createdAt: now,
      updatedAt: now,
      lastUpdated: now,
    );
  }
  
  /// Factory constructor for creating a new authenticated user set
  factory FlashcardSet.forUser({
    required String id,
    required String title,
    required String userId,
    required List<Flashcard> flashcards,
    String description = '',
    String? categoryId,
  }) {
    final now = DateTime.now();
    return FlashcardSet(
      id: id,
      title: title,
      description: description,
      flashcards: flashcards,
      userId: userId,
      isGuestData: false,
      categoryId: categoryId,
      createdAt: now,
      updatedAt: now,
      lastUpdated: now,
    );
  }
}
