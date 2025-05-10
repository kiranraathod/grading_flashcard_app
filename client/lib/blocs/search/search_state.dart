import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/interview_question.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  
  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchResults extends SearchState {
  final List<FlashcardSet> deckResults;
  final List<Flashcard> cardResults;
  final List<InterviewQuestion> questionResults;
  final String query;
  
  const SearchResults({
    required this.deckResults,
    required this.cardResults,
    required this.questionResults,
    required this.query,
  });
  
  @override
  List<Object> get props => [deckResults, cardResults, questionResults, query];
}

class SearchEmpty extends SearchState {
  final String query;
  
  const SearchEmpty(this.query);
  
  @override
  List<Object> get props => [query];
}

class SearchError extends SearchState {
  final String message;
  
  const SearchError(this.message);
  
  @override
  List<Object> get props => [message];
}
