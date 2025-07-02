class Flashcard {
  final String id;
  final String question;
  final String answer;
  final bool isMarkedForReview;
  final bool isCompleted;

  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.isMarkedForReview = false,
    this.isCompleted = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      isMarkedForReview: json['isMarkedForReview'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'isMarkedForReview': isMarkedForReview,
      'isCompleted': isCompleted,
    };
  }

  /// Create a copy of this flashcard with updated values
  Flashcard copyWith({
    String? id,
    String? question,
    String? answer,
    bool? isMarkedForReview,
    bool? isCompleted,
  }) {
    return Flashcard(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      isMarkedForReview: isMarkedForReview ?? this.isMarkedForReview,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
