import 'package:equatable/equatable.dart';
import '../../models/answer.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';

enum StudyStatus { initial, loading, loaded, answering, grading, authenticationRequired, editRequested, completed, error }

class StudyState extends Equatable {
  final StudyStatus status;
  final FlashcardSet? flashcardSet;
  final int currentIndex;
  final bool isMarkedForReview;
  final Answer? gradedAnswer;
  final String? errorMessage;
  
  const StudyState({
    this.status = StudyStatus.initial,
    this.flashcardSet,
    this.currentIndex = 0,
    this.isMarkedForReview = false,
    this.gradedAnswer,
    this.errorMessage,
  });
  
  Flashcard? get currentFlashcard {
    if (flashcardSet == null || flashcardSet!.flashcards.isEmpty) {
      return null;
    }
    if (currentIndex < 0 || currentIndex >= flashcardSet!.flashcards.length) {
      return null;
    }
    return flashcardSet!.flashcards[currentIndex];
  }
  
  bool get canGoNext => 
      flashcardSet != null && 
      currentIndex < flashcardSet!.flashcards.length - 1;
  
  bool get canGoPrevious => currentIndex > 0;
  
  /// Check if we're currently on the last card
  bool get isLastCard =>
      flashcardSet != null &&
      currentIndex == flashcardSet!.flashcards.length - 1;
  
  /// Check if the deck study session is completed
  bool get isDeckCompleted => status == StudyStatus.completed;
  
  StudyState copyWith({
    StudyStatus? status,
    FlashcardSet? flashcardSet,
    int? currentIndex,
    bool? isMarkedForReview,
    Answer? gradedAnswer,
    String? errorMessage,
  }) {
    return StudyState(
      status: status ?? this.status,
      flashcardSet: flashcardSet ?? this.flashcardSet,
      currentIndex: currentIndex ?? this.currentIndex,
      isMarkedForReview: isMarkedForReview ?? this.isMarkedForReview,
      gradedAnswer: gradedAnswer ?? this.gradedAnswer,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [
    status, 
    flashcardSet, 
    currentIndex, 
    isMarkedForReview, 
    gradedAnswer,
    errorMessage,
  ];
}