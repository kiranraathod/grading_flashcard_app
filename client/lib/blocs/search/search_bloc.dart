import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/flashcard_service.dart';
import '../../services/interview_service.dart';
// Removed unused imports
// import '../../models/flashcard.dart';
// import '../../models/flashcard_set.dart';
// import '../../models/interview_question.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final FlashcardService _flashcardService;
  final InterviewService _interviewService;
  Timer? _debounce;
  
  SearchBloc({
    required FlashcardService flashcardService,
    required InterviewService interviewService,
  }) : 
    _flashcardService = flashcardService,
    _interviewService = interviewService,
    super(SearchInitial()) {
    on<SearchTextChanged>(_onSearchTextChanged);
    on<ExecuteSearch>(_onExecuteSearch);
    on<ClearSearch>(_onClearSearch);
  }
  
  FutureOr<void> _onSearchTextChanged(SearchTextChanged event, Emitter<SearchState> emit) {
    final query = event.query;
    
    // Cancel any previous debounce timer
    _debounce?.cancel();
    
    if (query.isEmpty) {
      emit(SearchInitial());
      return null; // Explicitly return null for FutureOr<void>
    }
    
    // Debounce search to prevent excessive API calls
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length > 2) {
        // Only search when query is at least 3 characters
        add(ExecuteSearch(query));
      }
    });
  }
  
  FutureOr<void> _onExecuteSearch(ExecuteSearch event, Emitter<SearchState> emit) async {
    emit(SearchLoading());
    
    try {
      final query = event.query;
      
      // Execute searches in parallel
      final deckResults = await _flashcardService.searchDecks(query);
      final cardResults = await _flashcardService.searchCards(query);
      final questionResults = await _interviewService.searchQuestions(query);
      
      final hasResults = deckResults.isNotEmpty || 
                        cardResults.isNotEmpty || 
                        questionResults.isNotEmpty;
      
      if (hasResults) {
        emit(SearchResults(
          deckResults: deckResults,
          cardResults: cardResults,
          questionResults: questionResults,
          query: query,
        ));
      } else {
        emit(SearchEmpty(query));
      }
    } catch (e) {
      emit(SearchError('Failed to execute search: ${e.toString()}'));
    }
  }
  
  FutureOr<void> _onClearSearch(ClearSearch event, Emitter<SearchState> emit) {
    emit(SearchInitial());
  }
  
  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
