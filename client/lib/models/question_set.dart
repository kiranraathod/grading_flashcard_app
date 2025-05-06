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
    required this.description,
    required this.jobDescription,
    required this.questionIds,
    required this.createdAt,
  });
  
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
      id: json['id'],
      title: json['title'],
      description: json['description'],
      jobDescription: json['jobDescription'],
      questionIds: List<String>.from(json['questionIds']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}