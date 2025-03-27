class Flashcard {
  final String id;
  final String question;
  final String answer;
  final String? hint;
  final String? imageUrl;
  bool isMarkedForReview;

  Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    this.hint,
    this.imageUrl,
    this.isMarkedForReview = false,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      hint: json['hint'],
      imageUrl: json['imageUrl'],
      isMarkedForReview: json['isMarkedForReview'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'hint': hint,
      'imageUrl': imageUrl,
      'isMarkedForReview': isMarkedForReview,
    };
  }
}
