class InterviewQuestion {
  final String id;
  final String text;
  final String category; // technical, applied, case, behavioral, job
  final String subtopic;
  final String difficulty; // entry, mid, senior
  final String? answer; // Answer content
  bool isStarred;
  bool isCompleted;
  bool isDraft; // Whether this is a draft or published question
  
  InterviewQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.subtopic,
    required this.difficulty,
    this.answer,
    this.isStarred = false,
    this.isCompleted = false,
    this.isDraft = false,
  });
  
  InterviewQuestion copyWith({
    String? id,
    String? text,
    String? category,
    String? subtopic,
    String? difficulty,
    String? answer,
    bool? isStarred,
    bool? isCompleted,
    bool? isDraft,
  }) {
    return InterviewQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      subtopic: subtopic ?? this.subtopic,
      difficulty: difficulty ?? this.difficulty,
      answer: answer ?? this.answer,
      isStarred: isStarred ?? this.isStarred,
      isCompleted: isCompleted ?? this.isCompleted,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  /// Convert from JSON for server compatibility
  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String,
      subtopic: json['subtopic'] as String,
      difficulty: json['difficulty'] as String,
      answer: json['answer'] as String?,
      isStarred: json['is_starred'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      isDraft: json['is_draft'] as bool? ?? false,
    );
  }

  /// Convert to JSON for server compatibility
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'subtopic': subtopic,
      'difficulty': difficulty,
      'answer': answer,
      'is_starred': isStarred,
      'is_completed': isCompleted,
      'is_draft': isDraft,
    };
  }
}