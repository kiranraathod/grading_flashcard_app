import 'package:equatable/equatable.dart';
import '../../models/recently_viewed_item.dart';

/// Base class for all states in the RecentViewBloc
abstract class RecentViewState extends Equatable {
  const RecentViewState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any events
class RecentViewInitial extends RecentViewState {}

/// State during loading of recently viewed items
class RecentViewLoading extends RecentViewState {}

/// State when recently viewed items have been loaded successfully
class RecentViewLoaded extends RecentViewState {
  final List<RecentlyViewedItem> recentItems;
  final RecentItemType? activeFilter;
  
  const RecentViewLoaded({
    required this.recentItems,
    this.activeFilter,
  });
  
  @override
  List<Object?> get props => [recentItems, activeFilter];
  
  /// Create a copy of this state with specific values changed
  RecentViewLoaded copyWith({
    List<RecentlyViewedItem>? recentItems,
    RecentItemType? activeFilter,
    bool? clearFilter,
  }) {
    return RecentViewLoaded(
      recentItems: recentItems ?? this.recentItems,
      activeFilter: clearFilter == true ? null : (activeFilter ?? this.activeFilter),
    );
  }
  
  /// Filter items based on the active filter
  List<RecentlyViewedItem> get filteredItems {
    if (activeFilter == null) {
      return recentItems;
    }
    
    return recentItems
        .where((item) => activeFilter != null && item.type == activeFilter)
        .toList();
  }
}

/// State when an error has occurred
class RecentViewError extends RecentViewState {
  final String message;
  
  const RecentViewError({required this.message});
  
  @override
  List<Object> get props => [message];
}
