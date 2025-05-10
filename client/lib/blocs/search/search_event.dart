import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchTextChanged extends SearchEvent {
  final String query;
  
  const SearchTextChanged(this.query);
  
  @override
  List<Object> get props => [query];
}

class ExecuteSearch extends SearchEvent {
  final String query;
  
  const ExecuteSearch(this.query);
  
  @override
  List<Object> get props => [query];
}

class ClearSearch extends SearchEvent {}
