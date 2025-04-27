/// Enum defining the possible types of recently viewed items
enum RecentItemType {
  flashcard,
  interviewQuestion;

  @override
  String toString() {
    switch (this) {
      case RecentItemType.flashcard:
        return 'flashcard';
      case RecentItemType.interviewQuestion:
        return 'interviewQuestion';
    }
  }

  /// Create a RecentItemType from a string
  static RecentItemType fromString(String value) {
    switch (value) {
      case 'flashcard':
        return RecentItemType.flashcard;
      case 'interviewQuestion':
        return RecentItemType.interviewQuestion;
      default:
        throw ArgumentError('Unknown RecentItemType: $value');
    }
  }
}

/// Model representing a recently viewed item (flashcard or interview question)
class RecentlyViewedItem {
  final String id;           // Unique identifier for this view entry
  final String itemId;       // Reference to original item (flashcard or question id)
  final RecentItemType type; // Type of the item
  final String parentId;     // Reference to parent set or category
  final DateTime viewedAt;   // Timestamp of when the item was viewed
  final String question;     // Cached question text for display
  final String parentTitle;  // Cached parent title (set or category name)
  final bool isCompleted;    // Whether the item has been completed successfully

  RecentlyViewedItem({
    required this.id,
    required this.itemId,
    required this.type,
    required this.parentId,
    required this.viewedAt,
    required this.question,
    required this.parentTitle,
    this.isCompleted = false,
  });

  /// Create a recently viewed item from a flashcard
  factory RecentlyViewedItem.fromFlashcard({
    required String flashcardId,
    required String setId,
    required String question,
    required String setTitle,
    bool isCompleted = false,
  }) {
    return RecentlyViewedItem(
      id: 'recent-fc-${DateTime.now().millisecondsSinceEpoch}',
      itemId: flashcardId,
      type: RecentItemType.flashcard,
      parentId: setId,
      viewedAt: DateTime.now(),
      question: question,
      parentTitle: setTitle,
      isCompleted: isCompleted,
    );
  }

  /// Create a recently viewed item from an interview question
  factory RecentlyViewedItem.fromInterviewQuestion({
    required String questionId,
    required String category,
    required String question,
    required String categoryTitle,
    bool isCompleted = false,
  }) {
    return RecentlyViewedItem(
      id: 'recent-iq-${DateTime.now().millisecondsSinceEpoch}',
      itemId: questionId,
      type: RecentItemType.interviewQuestion,
      parentId: category,
      viewedAt: DateTime.now(),
      question: question,
      parentTitle: categoryTitle,
      isCompleted: isCompleted,
    );
  }

  /// Convert the recently viewed item to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'type': type.toString(),
      'parentId': parentId,
      'viewedAt': viewedAt.toIso8601String(),
      'question': question,
      'parentTitle': parentTitle,
      'isCompleted': isCompleted,
    };
  }

  /// Create a recently viewed item from a JSON map
  factory RecentlyViewedItem.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedItem(
      id: json['id'],
      itemId: json['itemId'],
      type: RecentItemType.fromString(json['type']),
      parentId: json['parentId'],
      viewedAt: DateTime.parse(json['viewedAt']),
      question: json['question'],
      parentTitle: json['parentTitle'],
      isCompleted: json['isCompleted'] ?? false, // Handle older data without this field
    );
  }

  @override
  String toString() {
    return 'RecentlyViewedItem{id: $id, type: $type, question: $question, isCompleted: $isCompleted}';
  }

  /// Convert a list of recently viewed items to a list of JSON maps
  static List<Map<String, dynamic>> listToJson(List<RecentlyViewedItem> items) {
    return items.map((item) => item.toJson()).toList();
  }

  /// Create a list of recently viewed items from a list of JSON maps
  static List<RecentlyViewedItem> listFromJson(List<dynamic> json) {
    return json.map((item) => RecentlyViewedItem.fromJson(item)).toList();
  }
}