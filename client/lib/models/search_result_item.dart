// Removed unused import: import 'package:flutter/foundation.dart';
import 'flashcard.dart';
import 'flashcard_set.dart';
import 'interview_question.dart';

// Enum to represent search result type
enum SearchResultType {
  deck,
  flashcard,
  interviewQuestion,
}

// Search result item model - represents a single search result
class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final String content;
  final SearchResultType type;
  final String parentId; // Parent set/category ID
  final String parentTitle; // Parent set/category title
  final bool isCompleted;
  final int relevanceScore;
  
  // Original objects
  final FlashcardSet? deckObject;
  final Flashcard? flashcardObject;
  final InterviewQuestion? questionObject;
  
  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.type,
    required this.parentId,
    required this.parentTitle,
    this.isCompleted = false,
    this.relevanceScore = 0,
    this.deckObject,
    this.flashcardObject,
    this.questionObject,
  });
  
  // Factory method to create from a flashcard set
  factory SearchResultItem.fromDeck(FlashcardSet deck, String query) {
    // Calculate a simple relevance score based on match position
    // Title matches are more relevant (lower index = higher relevance)
    final titleLower = deck.title.toLowerCase();
    final descLower = deck.description.toLowerCase();
    final queryLower = query.toLowerCase();
    
    int relevanceScore = 0;
    if (titleLower.contains(queryLower)) {
      // Title matches are most relevant (0-100 score)
      relevanceScore = 100 - min(100, titleLower.indexOf(queryLower));
    } else if (descLower.contains(queryLower)) {
      // Description matches are less relevant (0-50 score)
      relevanceScore = 50 - min(50, descLower.indexOf(queryLower));
    }
    
    return SearchResultItem(
      id: deck.id,
      title: deck.title,
      subtitle: deck.description,
      content: '${deck.flashcards.length} cards',
      type: SearchResultType.deck,
      parentId: '', // No parent for decks
      parentTitle: '', // No parent for decks
      relevanceScore: relevanceScore,
      deckObject: deck,
    );
  }
  
  // Factory method to create from a flashcard
  factory SearchResultItem.fromFlashcard(Flashcard card, FlashcardSet parentSet, String query) {
    // Calculate relevance score
    final questionLower = card.question.toLowerCase();
    final answerLower = card.answer.toLowerCase();
    final queryLower = query.toLowerCase();
    
    int relevanceScore = 0;
    if (questionLower.contains(queryLower)) {
      relevanceScore = 80 - min(80, questionLower.indexOf(queryLower));
    } else if (answerLower.contains(queryLower)) {
      relevanceScore = 40 - min(40, answerLower.indexOf(queryLower));
    }
    
    return SearchResultItem(
      id: card.id,
      title: card.question,
      subtitle: 'From: ${parentSet.title}',
      content: card.answer,
      type: SearchResultType.flashcard,
      parentId: parentSet.id,
      parentTitle: parentSet.title,
      isCompleted: card.isCompleted,
      relevanceScore: relevanceScore,
      flashcardObject: card,
    );
  }
  
  // Factory method to create from an interview question
  factory SearchResultItem.fromInterviewQuestion(InterviewQuestion question, String query) {
    // Handle nullable answer with null-coalescing, but text and category are non-nullable
    final titleText = question.text;
    final answerText = question.answer ?? '';
    final categoryText = question.category;
    
    // For non-nullable inputs, don't use null-aware operators
    final textLower = titleText.toLowerCase();
    final answerLower = answerText.toLowerCase();
    final categoryLower = categoryText.toLowerCase();
    final queryLower = query.toLowerCase();
    
    int relevanceScore = 0;
    if (textLower.contains(queryLower)) {
      relevanceScore = 90 - min(90, textLower.indexOf(queryLower));
    } else if (categoryLower.contains(queryLower)) {
      relevanceScore = 70 - min(70, categoryLower.indexOf(queryLower));
    } else if (answerLower.contains(queryLower)) {
      relevanceScore = 30 - min(30, answerLower.indexOf(queryLower));
    }
    
    return SearchResultItem(
      id: question.id,
      title: titleText,
      subtitle: 'Category: $categoryText',
      content: answerText,
      type: SearchResultType.interviewQuestion,
      parentId: categoryText,
      parentTitle: categoryText,
      isCompleted: question.isCompleted,
      relevanceScore: relevanceScore,
      questionObject: question,
    );
  }
  
  // Helper function to get minimum value
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
