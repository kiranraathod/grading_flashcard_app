class Flashcard {
  final String id;
  final String question;
  final String answer;
  bool isMarkedForReview;
  bool isCompleted;

  Flashcard({
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
}
