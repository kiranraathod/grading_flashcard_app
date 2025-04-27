import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/recently_viewed_item.dart';
import '../../services/recent_view_service.dart';
import 'recent_view_event.dart';
import 'recent_view_state.dart';

class RecentViewBloc extends Bloc<RecentViewEvent, RecentViewState> {
  final RecentViewService _recentViewService;
  
  RecentViewBloc({
    required RecentViewService recentViewService,
  }) : _recentViewService = recentViewService,
       super(RecentViewInitial()) {
    // Register event handlers
    on<LoadRecentViews>(_onLoadRecentViews);
    on<RecordFlashcardView>(_onRecordFlashcardView);
    on<RecordInterviewQuestionView>(_onRecordInterviewQuestionView);
    on<ClearRecentViews>(_onClearRecentViews);
    on<SetRecentViewFilter>(_onSetRecentViewFilter);
  }
  
  /// Handle loading recently viewed items
  Future<void> _onLoadRecentViews(
    LoadRecentViews event,
    Emitter<RecentViewState> emit,
  ) async {
    try {
      debugPrint('⭐ HANDLING LoadRecentViews EVENT ⭐');
      
      // Emit loading state
      emit(RecentViewLoading());
      debugPrint('  Emitted RecentViewLoading state');
      
      // Always get all items first to ensure we have the latest data
      var allItems = await _recentViewService.getRecentlyViewedItems(limit: 100);
      debugPrint('  Loaded ${allItems.length} items from RecentViewService');
      
      // Apply filtering if needed
      List<RecentlyViewedItem> items;
      if (event.filterType == null) {
        items = allItems;
        debugPrint('  No filter applied');
      } else if (event.filterType != null && event.filterType == RecentItemType.flashcard) {
        items = allItems.where((item) => item.type == RecentItemType.flashcard).toList();
        debugPrint('  Filtered to ${items.length} flashcards');
      } else {
        items = allItems.where((item) => item.type == RecentItemType.interviewQuestion).toList();
        debugPrint('  Filtered to ${items.length} interview questions');
      }
      
      // Always sort by timestamp (newest first)
      items.sort((a, b) => b.viewedAt.compareTo(a.viewedAt));
      
      // Apply limit after sorting
      items = items.take(event.limit).toList();
      debugPrint('  Limited to ${items.length} items');
      
      // Emit loaded state
      emit(RecentViewLoaded(
        recentItems: items,
        activeFilter: event.filterType,
      ));
      debugPrint('  Emitted RecentViewLoaded state with ${items.length} items');
    } catch (e) {
      debugPrint('Error loading recent views: $e');
      emit(RecentViewError(message: 'Failed to load recently viewed items'));
    }
  }
  
  /// Handle recording a flashcard view
  Future<void> _onRecordFlashcardView(
    RecordFlashcardView event,
    Emitter<RecentViewState> emit,
  ) async {
    try {
      debugPrint('⭐ HANDLING RecordFlashcardView EVENT ⭐');
      debugPrint('  Flashcard: ${event.flashcard.question.substring(0, min(30, event.flashcard.question.length))}...');
      debugPrint('  Set: ${event.set.title}');
      debugPrint('  Completed: ${event.isCompleted}');
      
      // Record the flashcard view
      await _recentViewService.recordFlashcardView(
        flashcard: event.flashcard,
        set: event.set,
        isCompleted: event.isCompleted,
      );
      
      // If we're in the loaded state, refresh the list
      if (state is RecentViewLoaded) {
        final currentState = state as RecentViewLoaded;
        debugPrint('  Current state is RecentViewLoaded, refreshing list with filter: ${currentState.activeFilter}');
        add(LoadRecentViews(filterType: currentState.activeFilter));
      } else {
        debugPrint('  Current state is not RecentViewLoaded (${state.runtimeType}), not refreshing list');
      }
    } catch (e) {
      debugPrint('❌ Error recording flashcard view: $e');
      // We don't change the state here to avoid disrupting the UI
    }
  }
  
  /// Handle recording an interview question view
  Future<void> _onRecordInterviewQuestionView(
    RecordInterviewQuestionView event,
    Emitter<RecentViewState> emit,
  ) async {
    try {
      // Record the interview question view
      await _recentViewService.recordInterviewQuestionView(
        question: event.question,
        category: event.category,
        isCompleted: event.isCompleted,
      );
      
      // If we're in the loaded state, refresh the list
      if (state is RecentViewLoaded) {
        final currentState = state as RecentViewLoaded;
        add(LoadRecentViews(filterType: currentState.activeFilter));
      }
    } catch (e) {
      debugPrint('Error recording interview question view: $e');
      // We don't change the state here to avoid disrupting the UI
    }
  }
  
  /// Handle clearing all recent views
  Future<void> _onClearRecentViews(
    ClearRecentViews event,
    Emitter<RecentViewState> emit,
  ) async {
    try {
      // Emit loading state
      emit(RecentViewLoading());
      
      // Clear view history
      await _recentViewService.clearViewHistory();
      
      // Emit loaded state with empty list
      emit(RecentViewLoaded(
        recentItems: [],
        activeFilter: null,
      ));
    } catch (e) {
      debugPrint('Error clearing recent views: $e');
      emit(RecentViewError(message: 'Failed to clear recently viewed items'));
    }
  }
  
  /// Handle setting a filter on the recent views
  void _onSetRecentViewFilter(
    SetRecentViewFilter event,
    Emitter<RecentViewState> emit,
  ) {
    if (state is RecentViewLoaded) {
      final currentState = state as RecentViewLoaded;
      
      // If the filter hasn't changed, do nothing
      if (currentState.activeFilter == event.filterType) {
        return;
      }
      
      // Load items with the new filter
      add(LoadRecentViews(filterType: event.filterType));
    }
  }
}
