import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/answer.dart';
import '../../models/app_error.dart';
import '../../models/flashcard.dart';
import '../../models/simple_auth_state.dart';
import '../../providers/unified_action_tracking_provider.dart';
import '../../services/api_service.dart';
import '../../services/error_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/unified_usage_limit_enforcer.dart';
import 'study_event.dart';
import 'study_state.dart';

class StudyBloc extends Bloc<StudyEvent, StudyState> {
  final ApiService _apiService;
  final FlashcardService _flashcardService;
  final ErrorService _errorService = ErrorService();
  final WidgetRef _ref; // 🆕 Add Riverpod ref for action tracking

  StudyBloc({
    required ApiService apiService,
    required FlashcardService flashcardService,
    required WidgetRef ref, // 🆕 Inject Riverpod ref
  }) : _apiService = apiService,
       _flashcardService = flashcardService,
       _ref = ref,
       super(const StudyState()) {
    on<StudyStarted>(_onStudyStarted);
    on<FlashcardAnswered>(_onFlashcardAnswered);
    on<NextFlashcardRequested>(_onNextFlashcardRequested);
    on<PreviousFlashcardRequested>(_onPreviousFlashcardRequested);
    on<DeckCompleted>(_onDeckCompleted);
    on<StudyResumedAfterAuth>(_onStudyResumedAfterAuth);
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
    debugPrint('🔍 StudyBloc: FlashcardAnswered event received - ${event.answer} for card ${event.flashcard.id}');
    
    if (state.currentFlashcard == null) return;

    // Clear any previous graded answer first to avoid showing old results
    emit(state.copyWith(
      status: StudyStatus.grading, 
      gradedAnswer: null
    ));

    try {
      // 🎯 SIMPLIFIED: Authentication is now handled at UI level
      // StudyBloc just processes grading and records actions
      debugPrint('🔍 StudyBloc: Processing grading request for card ${event.flashcard.id}');

      final answer = Answer(
        flashcardId: event.flashcard.id,
        question: event.flashcard.question,
        userAnswer: event.answer,
        correctAnswer: event.flashcard.answer,
      );
      
      // Enhanced API call with explicit timeout and error handling
      debugPrint('🔍 Making API call for card: ${event.flashcard.id}');
      final gradedAnswer = await _apiService.gradeAnswer(answer);
      debugPrint('🔍 API call completed - processing response');
      
      // 🎯 UPDATED: Record grading action AFTER successful grading using unified system
      debugPrint('🔍 StudyBloc: API call successful - recording grading action');
      final actionTracker = _ref.read(unifiedActionTrackerProvider.notifier);
      await actionTracker.recordAction(ActionType.flashcardGrading);
      
      // Debug: Show updated usage after recording
      final usageLimitEnforcer = _ref.read(unifiedUsageLimitEnforcerProvider);
      final updatedSummary = usageLimitEnforcer.getUsageSummary();
      debugPrint('📊 Updated usage after recording: ${updatedSummary['totalUsage']}/${updatedSummary['totalLimit']}');
      
      // 🎯 FIRST: Process the score and update completion status
      debugPrint('📊 Answer score received: ${gradedAnswer.score} for card ${event.flashcard.id}');
      
      // Only mark flashcard as completed if the answer is correct (score >= 70)
      // This is the ONLY place where progress is updated, and only on user answer submission
      if ((gradedAnswer.score ?? 0) >= 70) {
        debugPrint('✅ Marking card ${event.flashcard.id} as completed (score: ${gradedAnswer.score})');
        debugPrint('🎯 COMPLETION TRIGGER: Score ${gradedAnswer.score} >= 70 threshold');
        
        // Create a copy of the flashcard set with the updated flashcard
        final updatedFlashcards = List<Flashcard>.from(state.flashcardSet?.flashcards ?? []);
        final cardIndex = updatedFlashcards.indexWhere((card) => card.id == event.flashcard.id);
        
        if (cardIndex >= 0) {
          // Only update if the card wasn't already completed
          final isAlreadyCompleted = updatedFlashcards[cardIndex].isCompleted;
          
          debugPrint('📊 COMPLETION DEBUG: Card ${event.flashcard.id} (index: $cardIndex)');
          debugPrint('   Current completion status: ${isAlreadyCompleted ? "Already completed" : "Not completed"}');
          debugPrint('   Score achieved: ${gradedAnswer.score}');
          debugPrint('   Will mark as completed: ${!isAlreadyCompleted}');
          
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
            
            // Calculate and log new progress
            final completedCount = updatedFlashcards.where((card) => card.isCompleted).length;
            final totalCount = updatedFlashcards.length;
            final progressPercent = (completedCount / totalCount * 100).round();
            debugPrint('📊 NEW PROGRESS: $completedCount/$totalCount cards completed ($progressPercent%)');
            
            emit(
              state.copyWith(
                status: StudyStatus.loaded, 
                gradedAnswer: gradedAnswer,
                flashcardSet: updatedSet,
              ),
            );
            
            // 🎯 CRITICAL FIX: Save the updated progress to storage
            // Use a non-blocking save operation to avoid disrupting the main flow
            _flashcardService.updateSet(updatedSet).then((_) {
              debugPrint('✅ Flashcard progress saved to storage successfully');
            }).catchError((saveError) {
              debugPrint('❌ Failed to save flashcard progress: $saveError');
              // Note: We don't re-emit error state here to avoid disrupting user experience
              // The progress is still updated in memory for this session
            });
          } else {
            debugPrint('Card was already completed - updating graded answer but not progress');
            // Still update the graded answer for UI feedback, but don't change completion status
            emit(
              state.copyWith(
                status: StudyStatus.loaded, 
                gradedAnswer: gradedAnswer,
                // Keep the existing flashcardSet unchanged since completion status doesn't change
              ),
            );
          }
        } else {
          debugPrint('❌ CRITICAL: Card index not found - not updating progress');
          emit(
            state.copyWith(status: StudyStatus.loaded, gradedAnswer: gradedAnswer),
          );
        }
      } else {
        debugPrint('❌ Card ${event.flashcard.id} not completed (score: ${gradedAnswer.score}) - threshold is 70');
        debugPrint('📊 SCORE DEBUG: Need ${70 - (gradedAnswer.score ?? 0)} more points to complete this card');
        emit(
          state.copyWith(status: StudyStatus.loaded, gradedAnswer: gradedAnswer),
        );
      }
      
      // 🎯 FIXED: Removed POST-PROCESSING authentication check
      // Authentication should only trigger when user ATTEMPTS next action, not after completing current one
      // This eliminates the flickering issue and provides better UX
      
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ CRITICAL ERROR in StudyBloc._onFlashcardAnswered: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Also log to console with error level
      debugPrint('❌❌❌ StudyBloc API Error: $e');

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
                  : 'An error occurred while grading your answer. Please check your network connection.',
        ),
      );
    }
  }

  /// Handle navigation to next flashcard
  void _onNextFlashcardRequested(
    NextFlashcardRequested event,
    Emitter<StudyState> emit,
  ) {
    debugPrint('🔄 StudyBloc: NextFlashcardRequested - Current index: ${state.currentIndex}');
    
    if (state.flashcardSet == null) {
      debugPrint('❌ No flashcard set available for navigation');
      return;
    }

    final currentIndex = state.currentIndex;
    final totalCards = state.flashcardSet!.flashcards.length;
    
    if (currentIndex < totalCards - 1) {
      final nextIndex = currentIndex + 1;
      debugPrint('✅ Moving to next card: ${nextIndex + 1}/$totalCards');
      
      emit(state.copyWith(
        currentIndex: nextIndex,
        status: StudyStatus.loaded,
        gradedAnswer: null, // Clear previous graded answer
      ));
      
      debugPrint('🔄 Navigation complete - Now showing card ${nextIndex + 1}/$totalCards');
    } else {
      debugPrint('📚 Already at last card ($totalCards/$totalCards) - completing deck');
      // Complete the deck instead of staying on same card
      emit(state.copyWith(
        status: StudyStatus.completed,
        gradedAnswer: null, // Clear any graded answer
      ));
      debugPrint('🏁 Deck completed - ready to return to home screen');
    }
  }

  /// Handle navigation to previous flashcard
  void _onPreviousFlashcardRequested(
    PreviousFlashcardRequested event,
    Emitter<StudyState> emit,
  ) {
    debugPrint('🔄 StudyBloc: PreviousFlashcardRequested - Current index: ${state.currentIndex}');
    
    if (state.flashcardSet == null) {
      debugPrint('❌ No flashcard set available for navigation');
      return;
    }

    final currentIndex = state.currentIndex;
    final totalCards = state.flashcardSet!.flashcards.length;
    
    if (currentIndex > 0) {
      final previousIndex = currentIndex - 1;
      debugPrint('✅ Moving to previous card: ${previousIndex + 1}/$totalCards');
      
      emit(state.copyWith(
        currentIndex: previousIndex,
        status: StudyStatus.loaded,
        gradedAnswer: null, // Clear previous graded answer
      ));
      
      debugPrint('🔄 Navigation complete - Now showing card ${previousIndex + 1}/$totalCards');
    } else {
      debugPrint('📚 Already at first card (1/$totalCards) - no previous card available');
    }
  }

  /// Handle deck completion
  void _onDeckCompleted(
    DeckCompleted event,
    Emitter<StudyState> emit,
  ) {
    debugPrint('🏁 StudyBloc: DeckCompleted - Finishing study session');
    
    emit(state.copyWith(
      status: StudyStatus.completed,
      gradedAnswer: null, // Clear any graded answer
    ));
    
    debugPrint('✅ Study session completed - ready to return to home screen');
  }

  /// Handle resuming study after authentication
  void _onStudyResumedAfterAuth(
    StudyResumedAfterAuth event,
    Emitter<StudyState> emit,
  ) {
    debugPrint('🔄 StudyBloc: Study resumed after authentication');
    
    // Simply transition to loaded state to continue where we left off
    // The authentication system has already updated usage limits
    emit(state.copyWith(
      status: StudyStatus.loaded,
      gradedAnswer: null, // Clear any authentication-related state
    ));
    
    debugPrint('✅ Study session resumed - user can continue');
  }
}