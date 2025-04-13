class Answer {
  final String flashcardId;
  final String question;
  final String userAnswer;
  final String correctAnswer;  // Add this field
  final String? grade;
  final String? feedback;
  final List<String>? suggestions;

  Answer({
    required this.flashcardId,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,  // Make it required
    this.grade,
    this.feedback,
    this.suggestions,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      flashcardId: json['flashcardId'],
      question: json['question'],
      userAnswer: json['userAnswer'],
      correctAnswer: json['correctAnswer'],
      grade: json['grade'],
      feedback: json['feedback'],
      suggestions:
          json['suggestions'] != null
              ? List<String>.from(json['suggestions'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flashcardId': flashcardId,
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      if (grade != null) 'grade': grade,
      if (feedback != null) 'feedback': feedback,
      if (suggestions != null) 'suggestions': suggestions,
    };
  }
}
