class Suggestion {
  final String id;
  final String flashcardId;
  final String text;
  final DateTime createdAt;

  Suggestion({
    required this.id,
    required this.flashcardId,
    required this.text,
    required this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'],
      flashcardId: json['flashcardId'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flashcardId': flashcardId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return text;
  }
}
