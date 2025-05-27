/*
 * DEBUG TEST: API Development Count Mismatch
 * =========================================
 * 
 * Run this test to see exactly why API Development shows "2 questions" on the card
 * but only "1 question" when you click on it.
 * 
 * HOW TO USE:
 * 1. Add this code temporarily to your InterviewQuestionsScreen or HomeScreen
 * 2. Look for the debug output in your console
 * 3. Compare the counting vs filtering results
 * 
 * ADD THIS TO YOUR WIDGET (in initState or build method):
 */

void debugApiDevelopmentMismatch() {
  // Get the interview service
  final interviewService = Provider.of<InterviewService>(context, listen: false);
  
  print('=== MANUAL API DEVELOPMENT DEBUG ===');
  
  // 1. Check all questions that might be related to API Development
  final allQuestions = interviewService.questions; // This gets published questions only
  print('Total published questions: ${allQuestions.length}');
  
  var apiRelatedQuestions = allQuestions.where((q) => 
    q.subtopic.toLowerCase().contains('api') || 
    q.text.toLowerCase().contains('api') ||
    q.subtopic.trim() == 'API Development'
  ).toList();
  
  print('Found ${apiRelatedQuestions.length} API-related questions:');
  for (int i = 0; i < apiRelatedQuestions.length; i++) {
    final q = apiRelatedQuestions[i];
    print('  [$i] "${q.text}"');
    print('      Raw subtopic: "${q.subtopic}"');
    print('      Trimmed subtopic: "${q.subtopic.trim()}"');
    print('      Category: "${q.category}"');
    print('      CategoryId: "${q.categoryId}"');
    print('      isDraft: ${q.isDraft}');
    print('');
  }
  
  // 2. Test the exact counting logic
  print('=== TESTING COUNTING LOGIC ===');
  var countForApiDev = 0;
  for (final q in allQuestions) {
    final normalizedSubtopic = q.subtopic.trim();
    if (normalizedSubtopic == 'API Development') {
      countForApiDev++;
      print('COUNTED: "${q.text}" (subtopic: "$normalizedSubtopic")');
    }
  }
  print('Counting logic result: $countForApiDev questions');
  
  // 3. Test the exact filtering logic
  print('=== TESTING FILTERING LOGIC ===');
  final filteredQuestions = interviewService.getQuestionsByCategory('API Development', isSubtopic: true);
  print('Filtering logic result: ${filteredQuestions.length} questions');
  for (final q in filteredQuestions) {
    print('FILTERED: "${q.text}" (subtopic: "${q.subtopic.trim()}")');
  }
  
  // 4. Compare results
  print('=== COMPARISON ===');
  print('Counting found: $countForApiDev');
  print('Filtering found: ${filteredQuestions.length}');
  if (countForApiDev != filteredQuestions.length) {
    print('❌ MISMATCH DETECTED!');
    print('This explains why the card shows $countForApiDev but the screen shows ${filteredQuestions.length}');
  } else {
    print('✅ Counts match - the issue might be elsewhere');
  }
  
  print('=====================================');
}

/*
 * QUICK FIX TEST:
 * 
 * If you want to quickly test if there are draft questions causing the issue,
 * add this code:
 */

void checkForDraftApiQuestions() {
  final interviewService = Provider.of<InterviewService>(context, listen: false);
  
  // Get ALL questions including drafts
  final allQuestionsIncludingDrafts = interviewService.drafts + interviewService.questions;
  
  var apiDrafts = allQuestionsIncludingDrafts.where((q) => 
    q.isDraft && (
      q.subtopic.trim() == 'API Development' ||
      q.subtopic.toLowerCase().contains('api') ||
      q.text.toLowerCase().contains('api')
    )
  ).toList();
  
  print('Found ${apiDrafts.length} API Development DRAFT questions:');
  for (final q in apiDrafts) {
    print('  DRAFT: "${q.text}" (subtopic: "${q.subtopic.trim()}")');
  }
  
  if (apiDrafts.isNotEmpty) {
    print('❌ FOUND THE ISSUE: Draft questions are being counted but not displayed!');
  } else {
    print('✅ No draft questions found - issue is elsewhere');
  }
}

void main() {
  print('API Development Count Mismatch Debug Test');
  print('Add the debugApiDevelopmentMismatch() or checkForDraftApiQuestions() function');
  print('to your widget to identify the exact cause of the count mismatch.');
}
