class InterviewAnswer {
  final String questionId;
  final String questionText;
  final String userAnswer;
  final String category;
  final String difficulty;
  final int? score;
  final String? feedback;
  final List<String>? suggestions;

  InterviewAnswer({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.category,
    required this.difficulty,
    this.score,
    this.feedback,
    this.suggestions,
  });

  factory InterviewAnswer.fromJson(Map<String, dynamic> json) {
    return InterviewAnswer(
      questionId: json['questionId'],
      questionText: json['questionText'],
      userAnswer: json['userAnswer'],
      category: json['category'],
      difficulty: json['difficulty'],
      score: json['score'],
      feedback: json['feedback'],
      suggestions:
          json['suggestions'] != null
              ? List<String>.from(json['suggestions'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'userAnswer': userAnswer,
      'category': category,
      'difficulty': difficulty,
      if (score != null) 'score': score,
      if (feedback != null) 'feedback': feedback,
      if (suggestions != null) 'suggestions': suggestions,
    };
  }

  // Helper method to get letter grade from score
  String? getLetterGrade() {
    if (score == null) return null;
    
    if (score! >= 90) return 'A';
    if (score! >= 80) return 'B';
    if (score! >= 70) return 'C';
    if (score! >= 60) return 'D';
    return 'F';
  }
}