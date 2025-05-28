# Task 1.1: SharedPreferences Data Validation and Corruption Detection

## Priority Level
🚨 **CRITICAL BLOCKER** - Must be completed before any migration attempts

## Overview
Analyze and validate all SharedPreferences data to identify corruption patterns, missing fields, and inconsistent data structures that could cause migration failures.

## Background
Code analysis reveals extensive defensive programming throughout the application (200+ null checks, default value assignments), indicating systematic data corruption issues in SharedPreferences storage.

**Evidence of Issues:**
```dart
// From interview_service.dart - Line 250
final bool isDraft = item['isDraft'] ?? false; // Defaulting missing values
categoryId: item['categoryId'], // May be null/inconsistent  
isStarred: item['isStarred'] ?? false, // Defaulting missing values
isCompleted: item['isCompleted'] ?? false, // Defaulting missing values
```

## Implementation Steps

### Step 1: Create Data Validation Service
Create `lib/services/data_validation_service.dart`:

```dart
class DataValidationService {
  static const String _logTag = '[DATA_VALIDATION]';
  
  /// Comprehensive validation of all SharedPreferences data
  Future<DataValidationReport> validateAllStoredData() async {
    final report = DataValidationReport();
    
    // Validate flashcard sets
    await _validateFlashcardSets(report);
    
    // Validate interview questions  
    await _validateInterviewQuestions(report);
    
    // Validate user progress data
    await _validateUserProgress(report);
    
    // Validate recent view data
    await _validateRecentViewData(report);
    
    return report;
  }
  
  Future<void> _validateFlashcardSets(DataValidationReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = prefs.getStringList('flashcard_sets');
    
    if (setsJson == null) {
      report.addWarning('flashcard_sets', 'No flashcard sets found in storage');
      return;
    }
    
    for (int i = 0; i < setsJson.length; i++) {
      try {
        final setData = jsonDecode(setsJson[i]) as Map<String, dynamic>;
        _validateFlashcardSetStructure(setData, i, report);
      } catch (e) {
        report.addError('flashcard_sets', 'Invalid JSON in set $i: $e');
      }
    }
  }
  
  void _validateFlashcardSetStructure(Map<String, dynamic> setData, int index, DataValidationReport report) {
    final setPrefix = 'flashcard_sets[$index]';
    
    // Required fields validation
    if (!setData.containsKey('id') || setData['id'] == null) {
      report.addError(setPrefix, 'Missing or null id field');
    }
    
    if (!setData.containsKey('title') || setData['title'] == null || setData['title'].toString().isEmpty) {
      report.addError(setPrefix, 'Missing or empty title field');
    }
    
    if (!setData.containsKey('flashcards') || setData['flashcards'] is! List) {
      report.addError(setPrefix, 'Missing or invalid flashcards array');
    } else {
      final flashcards = setData['flashcards'] as List;
      for (int j = 0; j < flashcards.length; j++) {
        _validateFlashcardStructure(flashcards[j], '$setPrefix.flashcards[$j]', report);
      }
    }
    
    // Optional fields with type validation
    if (setData.containsKey('rating') && setData['rating'] is! num) {
      report.addWarning(setPrefix, 'Invalid rating type - should be number');
    }
    
    if (setData.containsKey('lastUpdated')) {
      try {
        DateTime.parse(setData['lastUpdated']);
      } catch (e) {
        report.addError(setPrefix, 'Invalid lastUpdated format: $e');
      }
    }
  }
  
  Future<void> _validateInterviewQuestions(DataValidationReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getString('interview_questions');
    
    if (questionsJson == null || questionsJson.isEmpty) {
      report.addWarning('interview_questions', 'No interview questions found in storage');
      return;
    }
    
    try {
      final List<dynamic> questions = jsonDecode(questionsJson);
      
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i] as Map<String, dynamic>;
        _validateInterviewQuestionStructure(question, i, report);
      }
    } catch (e) {
      report.addError('interview_questions', 'Invalid JSON structure: $e');
    }
  }
  
  void _validateInterviewQuestionStructure(Map<String, dynamic> question, int index, DataValidationReport report) {
    final questionPrefix = 'interview_questions[$index]';
    
    // Required fields
    final requiredFields = ['id', 'text', 'category', 'subtopic', 'difficulty'];
    for (final field in requiredFields) {
      if (!question.containsKey(field) || question[field] == null || question[field].toString().isEmpty) {
        report.addError(questionPrefix, 'Missing or empty required field: $field');
      }
    }
    
    // Critical field: categoryId (often missing and causes filtering issues)
    if (!question.containsKey('categoryId') || question['categoryId'] == null) {
      report.addCriticalError(questionPrefix, 'Missing categoryId field - will break Supabase filtering');
      
      // Suggest fix based on category field
      if (question.containsKey('category')) {
        final category = question['category'];
        final suggestedCategoryId = _mapCategoryToCategoryId(category);
        report.addSuggestion(questionPrefix, 'Suggested categoryId based on category "$category": $suggestedCategoryId');
      }
    }
    
    // Validate enum values
    if (question.containsKey('difficulty')) {
      final validDifficulties = ['entry', 'mid', 'senior'];
      if (!validDifficulties.contains(question['difficulty'])) {
        report.addError(questionPrefix, 'Invalid difficulty value: ${question['difficulty']}. Must be one of: ${validDifficulties.join(', ')}');
      }
    }
    
    // Boolean fields validation
    final boolFields = ['isDraft', 'isStarred', 'isCompleted'];
    for (final field in boolFields) {
      if (question.containsKey(field) && question[field] is! bool) {
        report.addWarning(questionPrefix, 'Field $field should be boolean, found: ${question[field].runtimeType}');
      }
    }
  }
  
  String _mapCategoryToCategoryId(String category) {
    final mapping = {
      'technical': 'data_analysis',
      'applied': 'machine_learning',
      'behavioral': 'python',
      'case': 'statistics',
      'job': 'web_development',
    };
    return mapping[category] ?? 'data_analysis';
  }
}

class DataValidationReport {
  final List<ValidationIssue> errors = [];
  final List<ValidationIssue> warnings = [];
  final List<ValidationIssue> criticalErrors = [];
  final List<ValidationIssue> suggestions = [];
  
  void addError(String location, String message) {
    errors.add(ValidationIssue(location, message, ValidationSeverity.error));
  }
  
  void addWarning(String location, String message) {
    warnings.add(ValidationIssue(location, message, ValidationSeverity.warning));
  }
  
  void addCriticalError(String location, String message) {
    criticalErrors.add(ValidationIssue(location, message, ValidationSeverity.critical));
  }
  
  void addSuggestion(String location, String message) {
    suggestions.add(ValidationIssue(location, message, ValidationSeverity.suggestion));
  }
  
  bool get hasBlockingIssues => criticalErrors.isNotEmpty || errors.isNotEmpty;
  
  void printReport() {
    print('=== DATA VALIDATION REPORT ===');
    
    if (criticalErrors.isNotEmpty) {
      print('\n🚨 CRITICAL ERRORS (${criticalErrors.length}):');
      for (final issue in criticalErrors) {
        print('  ❌ ${issue.location}: ${issue.message}');
      }
    }
    
    if (errors.isNotEmpty) {
      print('\n❌ ERRORS (${errors.length}):');
      for (final issue in errors) {
        print('  ❌ ${issue.location}: ${issue.message}');
      }
    }
    
    if (warnings.isNotEmpty) {
      print('\n⚠️ WARNINGS (${warnings.length}):');
      for (final issue in warnings) {
        print('  ⚠️ ${issue.location}: ${issue.message}');
      }
    }
    
    if (suggestions.isNotEmpty) {
      print('\n💡 SUGGESTIONS (${suggestions.length}):');
      for (final issue in suggestions) {
        print('  💡 ${issue.location}: ${issue.message}');
      }
    }
    
    print('\n=== SUMMARY ===');
    print('Critical Errors: ${criticalErrors.length}');
    print('Errors: ${errors.length}');
    print('Warnings: ${warnings.length}');
    print('Migration Blocked: ${hasBlockingIssues ? 'YES' : 'NO'}');
  }
}

class ValidationIssue {
  final String location;
  final String message;
  final ValidationSeverity severity;
  
  ValidationIssue(this.location, this.message, this.severity);
}

enum ValidationSeverity { critical, error, warning, suggestion }
```

### Step 2: Create Validation Test Screen
Create `lib/screens/data_validation_screen.dart` for manual testing:

```dart
class DataValidationScreen extends StatefulWidget {
  @override
  _DataValidationScreenState createState() => _DataValidationScreenState();
}

class _DataValidationScreenState extends State<DataValidationScreen> {
  DataValidationReport? _report;
  bool _isValidating = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Validation'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _runValidation,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isValidating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Validating stored data...'),
          ],
        ),
      );
    }
    
    if (_report == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tap refresh to validate data'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _runValidation,
              child: Text('Run Validation'),
            ),
          ],
        ),
      );
    }
    
    return _buildReport();
  }
  
  Widget _buildReport() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          SizedBox(height: 16),
          if (_report!.criticalErrors.isNotEmpty) _buildIssueSection('Critical Errors', _report!.criticalErrors, Colors.red),
          if (_report!.errors.isNotEmpty) _buildIssueSection('Errors', _report!.errors, Colors.orange),
          if (_report!.warnings.isNotEmpty) _buildIssueSection('Warnings', _report!.warnings, Colors.yellow),
          if (_report!.suggestions.isNotEmpty) _buildIssueSection('Suggestions', _report!.suggestions, Colors.blue),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    final isBlocked = _report!.hasBlockingIssues;
    
    return Card(
      color: isBlocked ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBlocked ? Icons.error : Icons.check_circle,
                  color: isBlocked ? Colors.red : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Migration Status: ${isBlocked ? 'BLOCKED' : 'READY'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isBlocked ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('Critical Errors: ${_report!.criticalErrors.length}'),
            Text('Errors: ${_report!.errors.length}'),
            Text('Warnings: ${_report!.warnings.length}'),
            Text('Suggestions: ${_report!.suggestions.length}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIssueSection(String title, List<ValidationIssue> issues, Color color) {
    return Card(
      child: ExpansionTile(
        title: Text(
          '$title (${issues.length})',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        children: issues.map((issue) => ListTile(
          leading: Icon(Icons.arrow_right, color: color),
          title: Text(issue.location),
          subtitle: Text(issue.message),
        )).toList(),
      ),
    );
  }
  
  Future<void> _runValidation() async {
    setState(() {
      _isValidating = true;
      _report = null;
    });
    
    try {
      final validationService = DataValidationService();
      final report = await validationService.validateAllStoredData();
      
      setState(() {
        _report = report;
        _isValidating = false;
      });
      
      // Print to console for debugging
      report.printReport();
    } catch (e) {
      setState(() {
        _isValidating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Validation failed: $e')),
      );
    }
  }
}
```

### Step 3: Add Validation Route to Main App
In `lib/main.dart`, add route for testing:

```dart
routes: {
  '/job-description-generator': (context) => const JobDescriptionQuestionGeneratorScreen(),
  '/data-validation': (context) => DataValidationScreen(), // ADD THIS LINE
},
```

### Step 4: Create Validation Command
Add to `lib/services/debug_service.dart`:

```dart
class DebugService {
  static Future<void> runDataValidation() async {
    print('Starting comprehensive data validation...');
    
    final validationService = DataValidationService();
    final report = await validationService.validateAllStoredData();
    
    report.printReport();
    
    if (report.hasBlockingIssues) {
      print('\n🚨 MIGRATION BLOCKED - Fix critical errors and errors before proceeding');
    } else {
      print('\n✅ Data validation passed - Ready for migration');
    }
  }
}
```

## Acceptance Criteria

- [ ] DataValidationService correctly identifies all data corruption patterns
- [ ] Validation report clearly categorizes issues by severity
- [ ] All missing `categoryId` fields are identified and mapped suggestions provided
- [ ] Validation can be run both programmatically and through UI
- [ ] Console output provides clear migration readiness status
- [ ] Report includes specific location information for each issue
- [ ] Validation covers all SharedPreferences data types (flashcards, questions, progress, recent views)

## Testing Instructions

1. **Run validation via debug console:**
   ```dart
   await DebugService.runDataValidation();
   ```

2. **Access validation screen:**
   - Navigate to `/data-validation` route
   - Tap "Run Validation" button
   - Review detailed report

3. **Test with corrupted data:**
   - Manually corrupt some SharedPreferences JSON
   - Run validation to confirm detection
   - Verify suggested fixes are appropriate

## Expected Issues to Find

Based on code analysis, expect to find:
- Missing `categoryId` fields in interview questions
- Inconsistent boolean field types (`"false"` strings instead of `false` booleans)
- Invalid difficulty enum values
- Corrupted JSON structures
- Missing required fields in flashcard sets
- Invalid date formats in `lastUpdated` fields

## Next Steps
After completing this task:
- Proceed to Task 1.2: Data Cleanup and Repair
- Document all found issues for migration planning
- Create automated tests based on validation results

## Related Files
- `lib/services/interview_service.dart` (extensive defensive programming)
- `lib/services/flashcard_service.dart` (error handling patterns)
- `lib/models/interview_question.dart` (data structure definition)
- `lib/models/flashcard_set.dart` (data structure definition)

## Dependencies
- `shared_preferences` package
- `dart:convert` for JSON handling
- Access to all existing service files for data structure reference