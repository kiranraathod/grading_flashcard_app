class Answer {
  final String flashcardId;
  final String question;
  final String userAnswer;
  final String correctAnswer;  // Add this field
  final int? score;  // Changed from String? grade to int? score
  final String? feedback;
  final List<String>? suggestions;

  Answer({
    required this.flashcardId,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,  // Make it required
    this.score,  // Changed from grade
    this.feedback,
    this.suggestions,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      flashcardId: json['flashcardId'],
      question: json['question'],
      userAnswer: json['userAnswer'],
      correctAnswer: json['correctAnswer'],
      score: json['score'],  // Changed from grade
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
      if (score != null) 'score': score,  // Changed from grade
      if (feedback != null) 'feedback': feedback,
      if (suggestions != null) 'suggestions': suggestions,
    };
  }

  // Helper method to get letter grade from score (for transition period)
  String? getLetterGrade() {
    if (score == null) return null;
    
    if (score! >= 90) return 'A';
    if (score! >= 80) return 'B';
    if (score! >= 70) return 'C';
    if (score! >= 60) return 'D';
    return 'F';
  }
  
  // Helper method to check completion (score >= 70)
  bool get isCompleted => (score ?? 0) >= 70;
  
  // Helper method to get score description
  String getScoreDescription() {
    final currentScore = score ?? 0;
    if (currentScore >= 90) return 'Excellent Answer';
    if (currentScore >= 80) return 'Good Answer';
    if (currentScore >= 70) return 'Satisfactory Answer';
    if (currentScore >= 60) return 'Needs Improvement';
    if (currentScore > 0) return 'Incomplete Answer';
    return 'No Score';
  }
}
