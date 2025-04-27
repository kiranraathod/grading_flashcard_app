import 'package:equatable/equatable.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_set.dart';
import '../../models/interview_question.dart';
import '../../models/recently_viewed_item.dart';

/// Base class for all events in the RecentViewBloc
abstract class RecentViewEvent extends Equatable {
  const RecentViewEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load recently viewed items
class LoadRecentViews extends RecentViewEvent {
  final RecentItemType? filterType; // Optional filter by type
  final int limit;
  
  const LoadRecentViews({
    this.filterType,
    this.limit = 20,
  });
  
  @override
  List<Object?> get props => [filterType, limit];
}

/// Event to record a flashcard view
class RecordFlashcardView extends RecentViewEvent {
  final Flashcard flashcard;
  final FlashcardSet set;
  final bool isCompleted;
  
  const RecordFlashcardView({
    required this.flashcard,
    required this.set,
    this.isCompleted = false,
  });
  
  @override
  List<Object?> get props => [flashcard.id, set.id, isCompleted];
}

/// Event to record an interview question view
class RecordInterviewQuestionView extends RecentViewEvent {
  final InterviewQuestion question;
  final String category;
  final bool isCompleted;
  
  const RecordInterviewQuestionView({
    required this.question,
    required this.category,
    this.isCompleted = false,
  });
  
  @override
  List<Object?> get props => [question.id, category, isCompleted];
}

/// Event to clear all recent views
class ClearRecentViews extends RecentViewEvent {}

/// Event to set a filter on the recent views
class SetRecentViewFilter extends RecentViewEvent {
  final RecentItemType? filterType;
  
  const SetRecentViewFilter({
    this.filterType,
  });
  
  @override
  List<Object?> get props => [filterType];
}
