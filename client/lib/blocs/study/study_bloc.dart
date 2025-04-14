import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../models/answer.dart';
import '../../models/app_error.dart';
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

      emit(
        state.copyWith(status: StudyStatus.loaded, gradedAnswer: gradedAnswer),
      );
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