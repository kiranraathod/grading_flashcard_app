import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';

abstract class StudyEvent extends Equatable {
  const StudyEvent();

  @override
  List<Object?> get props => [];
}

class StudyStarted extends StudyEvent {
  final FlashcardSet flashcardSet;

  const StudyStarted({required this.flashcardSet});

  @override
  List<Object?> get props => [flashcardSet];
}

class FlashcardAnswered extends StudyEvent {
  final String answer;
  final Flashcard flashcard;

  const FlashcardAnswered({required this.answer, required this.flashcard});

  @override
  List<Object?> get props => [answer, flashcard];
}

class NextFlashcardRequested extends StudyEvent {
  const NextFlashcardRequested();
}

class PreviousFlashcardRequested extends StudyEvent {
  const PreviousFlashcardRequested();
}

class DeckCompleted extends StudyEvent {
  const DeckCompleted();
}

class FlashcardMarkedForReview extends StudyEvent {
  final Flashcard flashcard;
  final bool isMarked;

  const FlashcardMarkedForReview({
    required this.flashcard,
    required this.isMarked,
  });

  @override
  List<Object?> get props => [flashcard, isMarked];
}

class StudyResumedAfterAuth extends StudyEvent {
  const StudyResumedAfterAuth();
}

class EditFlashcardSetRequested extends StudyEvent {}

class UpdateFlashcardSet extends StudyEvent {
  final FlashcardSet flashcardSet;

  const UpdateFlashcardSet({required this.flashcardSet});

  @override
  List<Object?> get props => [flashcardSet];
}
