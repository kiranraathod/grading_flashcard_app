import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/answer.dart';
import '../../models/app_error.dart';
import '../../models/flashcard.dart';
import '../../services/api_service.dart';
import '../../services/error_service.dart';
import 'study_event.dart';
import 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  final ApiService _apiService;
  final ErrorService _errorService = ErrorService();

  StudyBloc({required ApiService apiService})
    : _apiService = apiService,
      super(const StudyState()) {
    on<StudyStarted>(_onStudyStarted);
    on<FlashcardAnswered>(_onFlashcardAnswered);
    on<FlashcardMarkedForReview>(_onFlashcardMarkedForReview);
    on<NextFlashcardRequested>(_onNextFlashcardRequested);
    on<PreviousFlashcardRequested>(_onPreviousFlashcardRequested);
    on<EditFlashcardSetRequested>(_onEditFlashcardSetRequested);
  }

  void _onStudyStarted(StudyStarted event, Emitter<StudyState> emit) {
    // Check if flashcard set has cards
    if (event.flashcardSet.flashcards.isEmpty) {
      emit(
        state.copyWith(
          status: StudyStatus.error,
          flashcardSet: event.flashcardSet,
          errorMessage: "This flashcard set is empty. Please add flashcards to study.",
        ),
      );
      return;
    }
    
    emit(
      state.copyWith(
        status: StudyStatus.loaded,
        flashcardSet: event.flashcardSet,
        currentIndex: 0,
        isMarkedForReview: false,
        gradedAnswer: null,
      ),
    );
  }

  Future<void> _onFlashcardAnswered(
    FlashcardAnswered event,
    Emitter<StudyState> emit,
  ) async {
    if (state.currentFlashcard == null) return;

    // Clear any previous graded answer first to avoid showing old results
    emit(state.copyWith(
      status: StudyStatus.grading, 
      gradedAnswer: null
    ));

    try {
      final answer = Answer(
        flashcardId: event.flashcard.id,
        question: event.flashcard.question,
        userAnswer: event.answer,
        correctAnswer: event.flashcard.answer,
      );

      final gradedAnswer = await _apiService.gradeAnswer(answer);
      
      // Log the grade received for debugging
      debugPrint('Answer grade received: ${gradedAnswer.grade} for card ${event.flashcard.id}');
      
      // Only mark flashcard as completed if the answer is correct (grade A, B, or C)
      // This is the ONLY place where progress is updated, and only on user answer submission
      if (gradedAnswer.grade == 'A' || gradedAnswer.grade == 'B' || gradedAnswer.grade == 'C') {
        debugPrint('Marking card ${event.flashcard.id} as completed');
        
        // Create a copy of the flashcard set with the updated flashcard
        final updatedFlashcards = List<Flashcard>.from(state.flashcardSet?.flashcards ?? []);
        final cardIndex = updatedFlashcards.indexWhere((card) => card.id == event.flashcard.id);
        
        if (cardIndex >= 0) {
          // Only update if the card wasn't already completed
          final isAlreadyCompleted = updatedFlashcards[cardIndex].isCompleted;
          
          if (!isAlreadyCompleted) {
            debugPrint('Card was not previously completed - updating progress');
            
            // Update the specific flashcard's completion status
            final updatedCard = Flashcard(
              id: updatedFlashcards[cardIndex].id,
              question: updatedFlashcards[cardIndex].question,
              answer: updatedFlashcards[cardIndex].answer,
              isMarkedForReview: updatedFlashcards[cardIndex].isMarkedForReview,
              isCompleted: true,
            );
            
            updatedFlashcards[cardIndex] = updatedCard;
            
            // Create updated flashcard set
            final updatedSet = state.flashcardSet!.copyWith(
              flashcards: updatedFlashcards,
              lastUpdated: DateTime.now(), // Update the timestamp to trigger rerenders
            );
            
            emit(
              state.copyWith(
                status: StudyStatus.loaded, 
                gradedAnswer: gradedAnswer,
                flashcardSet: updatedSet,
              ),
            );
          } else {
            debugPrint('Card was already completed - not updating progress');
            emit(
              state.copyWith(status: StudyStatus.loaded, gradedAnswer: gradedAnswer),
            );
          }
        } else {
          debugPrint('Card index not found - not updating progress');
          emit(
            state.copyWith(status: StudyStatus.loaded, gradedAnswer: gradedAnswer),
          );
        }
      } else {
        debugPrint('Answer incorrect (grade: ${gradedAnswer.grade}) - not updating progress');
        emit(
          state.copyWith(status: StudyStatus.loaded, gradedAnswer: gradedAnswer),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error in StudyBloc._onFlashcardAnswered: $e');

      // Report error through error service
      if (e is! AppError) {
        _errorService.reportError(
          AppError.unknown(
            e,
            stackTrace: stackTrace,
            context: {
              'flashcardId': event.flashcard.id,
              'question': event.flashcard.question,
            },
          ),
        );
      }

      emit(
        state.copyWith(
          status: StudyStatus.error,
          errorMessage:
              e is AppError
                  ? e.userFriendlyMessage
                  : 'An error occurred while grading your answer.',
        ),
      );
    }
  }

  void _onFlashcardMarkedForReview(
    FlashcardMarkedForReview event,
    Emitter<StudyState> emit,
  ) {
    emit(state.copyWith(isMarkedForReview: event.isMarked));
  }

  void _onNextFlashcardRequested(
    NextFlashcardRequested event,
    Emitter<StudyState> emit,
  ) {
    if (!state.canGoNext) return;

    // Clear the graded answer first to ensure UI consistency
    emit(
      state.copyWith(
        gradedAnswer: null,
        isMarkedForReview: false,
      ),
    );
    
    // Then update the index in a separate emission to ensure clean state transition
    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
      ),
    );
  }

  void _onPreviousFlashcardRequested(
    PreviousFlashcardRequested event,
    Emitter<StudyState> emit,
  ) {
    if (!state.canGoPrevious) return;

    // Clear the graded answer first to ensure UI consistency
    emit(
      state.copyWith(
        gradedAnswer: null,
        isMarkedForReview: false,
      ),
    );
    
    // Then update the index in a separate emission
    emit(
      state.copyWith(
        currentIndex: state.currentIndex - 1,
      ),
    );
  }

  void _onEditFlashcardSetRequested(
    EditFlashcardSetRequested event,
    Emitter<StudyState> emit,
  ) {
    // No state change needed for this event
    // Navigation to edit screen will be handled in the UI
  }
}