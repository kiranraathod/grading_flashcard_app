class QuestionSet {
  final String id;
  final String title;
  final String description;
  final String jobDescription;
  final List<String> questionIds;
  final DateTime createdAt;
  
  QuestionSet({
    required this.id,
    required this.title,
    this.description = '',
    this.jobDescription = '',
    required this.questionIds,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'jobDescription': jobDescription,
      'questionIds': questionIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
  
  // For deserialization
  factory QuestionSet.fromJson(Map<String, dynamic> json) {
    return QuestionSet(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      jobDescription: json['jobDescription'] ?? '',
      questionIds: List<String>.from(json['questionIds'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
    );
  }
  
  // Create a copy with overridden properties
  QuestionSet copyWith({
    String? id,
    String? title,
    String? description,
    String? jobDescription,
    List<String>? questionIds,
    DateTime? createdAt,
  }) {
    return QuestionSet(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      jobDescription: jobDescription ?? this.jobDescription,
      questionIds: questionIds ?? this.questionIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}