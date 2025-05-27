import 'package:flutter/material.dart';

/// Debug script to identify subtopic count mismatches
/// 
/// ISSUE: API Development card shows "2 questions" but clicking shows only 1 question
/// 
/// ROOT CAUSE ANALYSIS:
/// The count mismatch suggests differences between:
/// 1. Question counting logic in _calculateLocalCategoryCounts() and _loadCategoryCounts()
/// 2. Question filtering logic in getQuestionsByCategory() with isSubtopic=true
///
/// POTENTIAL CAUSES:
/// 1. Case sensitivity: "api development" vs "API Development"
/// 2. Whitespace issues: "API Development " vs "API Development"
/// 3. Draft questions being counted but not displayed
/// 4. Server vs local questions having different subtopic formatting
/// 5. Questions with categoryId="technical" mapping to different UI categories

void main() {
  debugQuestionCountMismatch();
}

/// Debug function to trace question count mismatch
void debugQuestionCountMismatch() {
  print('=== DEBUGGING API DEVELOPMENT COUNT MISMATCH ===');
  print('Expected: 2 questions (from card)');
  print('Actual: 1 question (from screen)');
  print('');
  
  print('STEP 1: Check question counting logic');
  print('In _calculateLocalCategoryCounts():');
  print('- Uses: question.subtopic.trim() as key');
  print('- Counts all publishedQuestions (where !q.isDraft)');
  print('');
  
  print('STEP 2: Check question filtering logic');
  print('In getQuestionsByCategory() with isSubtopic=true:');
  print('- Uses: question.subtopic.toLowerCase() == uiCategory.toLowerCase()');
  print('- Filters all questions (where !q.isDraft)');
  print('');
  
  print('POTENTIAL MISMATCHES:');
  print('1. Counting uses .trim() but filtering uses .toLowerCase()');
  print('2. Server questions might have different subtopic formatting');
  print('3. Draft questions counted but not displayed');
  print('4. Questions from different sources (server vs local)');
  print('');
  
  print('DEBUGGING STEPS TO ADD:');
  print('1. Add debug prints to _calculateLocalCategoryCounts()');
  print('2. Add debug prints to getQuestionsByCategory()');
  print('3. Check for case sensitivity and whitespace issues');
  print('4. Verify draft question handling');
}

/// Suggested debug additions for home_screen.dart
class DebugHomeScreen {
  /// ENHANCED _calculateLocalCategoryCounts with debug prints
  static Map<String, int> calculateLocalCategoryCounts(dynamic interviewService) {
    final localCounts = <String, int>{};
    
    // Get all published questions
    final publishedQuestions = interviewService.questions;
    print('=== DEBUG: Calculating Local Category Counts ===');
    print('Total published questions: ${publishedQuestions.length}');
    
    for (final question in publishedQuestions) {
      // Use subtopic as the key instead of main category
      final subtopic = question.subtopic.trim();
      print('Question: "${question.text}"');
      print('  - Raw subtopic: "${question.subtopic}"');
      print('  - Trimmed subtopic: "$subtopic"');
      print('  - isDraft: ${question.isDraft}');
      
      if (subtopic.isNotEmpty) {
        localCounts[subtopic] = (localCounts[subtopic] ?? 0) + 1;
        print('  - Added to subtopic "$subtopic", new count: ${localCounts[subtopic]}');
      } else {
        localCounts['General'] = (localCounts['General'] ?? 0) + 1;
        print('  - Added to General category, new count: ${localCounts['General']}');
      }
      print('');
    }
    
    print('Final local subtopic counts:');
    for (final entry in localCounts.entries) {
      print('  ${entry.key}: ${entry.value}');
    }
    print('=== END DEBUG ===');
    
    return localCounts;
  }
}

/// Suggested debug additions for interview_service.dart
class DebugInterviewService {
  /// ENHANCED getQuestionsByCategory with debug prints
  static List<dynamic> getQuestionsByCategory(
    List<dynamic> questions, 
    String uiCategory, 
    {bool isSubtopic = false}
  ) {
    print('=== DEBUG: Getting Questions by Category ===');
    print('Category: $uiCategory');
    print('isSubtopic: $isSubtopic');
    print('Total questions to filter: ${questions.length}');
    
    final filteredQuestions = questions.where((question) {
      print('Checking question: "${question.text}"');
      print('  - Raw subtopic: "${question.subtopic}"');
      print('  - isDraft: ${question.isDraft}');
      
      if (isSubtopic) {
        final questionSubtopic = question.subtopic.toLowerCase();
        final targetSubtopic = uiCategory.toLowerCase();
        final matches = questionSubtopic == targetSubtopic;
        
        print('  - Question subtopic (lower): "$questionSubtopic"');
        print('  - Target subtopic (lower): "$targetSubtopic"');
        print('  - Matches: $matches');
        
        return matches;
      }
      
      // Original category matching logic would go here
      return false;
    }).toList();
    
    print('Filtered questions count: ${filteredQuestions.length}');
    print('Questions found:');
    for (final q in filteredQuestions) {
      print('  - "${q.text}" (subtopic: "${q.subtopic}")');
    }
    print('=== END DEBUG ===');
    
    return filteredQuestions;
  }
}

/// Quick fix suggestions
class QuickFixes {
  static void printSuggestions() {
    print('');
    print('=== QUICK FIX SUGGESTIONS ===');
    print('');
    print('FIX 1: Normalize subtopic comparison');
    print('Change _calculateLocalCategoryCounts to use:');
    print('  final subtopic = question.subtopic.trim().toLowerCase();');
    print('');
    print('FIX 2: Ensure consistent filtering');
    print('Change getQuestionsByCategory to use:');
    print('  final matches = question.subtopic.trim().toLowerCase() == uiCategory.trim().toLowerCase();');
    print('');
    print('FIX 3: Add comprehensive debugging');
    print('Add debug prints to both counting and filtering methods');
    print('to trace exactly which questions are being counted vs filtered');
    print('');
    print('FIX 4: Check draft handling');
    print('Ensure both methods use same draft filtering:');
    print('  final publishedQuestions = questions.where((q) => !q.isDraft).toList();');
  }
}
