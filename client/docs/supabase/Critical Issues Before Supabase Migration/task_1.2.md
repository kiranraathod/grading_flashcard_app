# Task 1.2: Data Cleanup and Repair Implementation

## Priority Level
🚨 **CRITICAL BLOCKER** - Must be completed after Task 1.1

## Overview
Implement automated data cleanup and repair mechanisms to fix corruption issues identified in Task 1.1, ensuring all SharedPreferences data is migration-ready.

## Prerequisites
- ✅ Task 1.1 completed (Data Validation Service implemented)
- ✅ Full data validation report generated
- ✅ Backup strategy in place (Task 1.3)

## Background
Based on Task 1.1 findings, implement targeted repairs for:
- Missing `categoryId` fields in interview questions
- Corrupted boolean values stored as strings
- Invalid enum values in difficulty fields  
- Malformed JSON structures
- Missing required fields

## Implementation Steps

### Step 1: Create Data Repair Service
Create `lib/services/data_repair_service.dart`:

```dart
class DataRepairService {
  final DataValidationService _validator = DataValidationService();
  
  /// Main repair method - fixes all identified issues
  Future<DataRepairResult> repairAllData() async {
    final result = DataRepairResult();
    
    // Create backup before any repairs
    await _createRepairBackup(result);
    
    // Repair flashcard sets
    await _repairFlashcardSets(result);
    
    // Repair interview questions (most critical)
    await _repairInterviewQuestions(result);
    
    // Repair user progress data
    await _repairUserProgress(result);
    
    // Validate repairs
    await _validateRepairs(result);
    
    return result;
  }
  
  Future<void> _repairInterviewQuestions(DataRepairResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = prefs.getString('interview_questions');
    
    if (questionsJson == null || questionsJson.isEmpty) {
      result.addInfo('No interview questions to repair');
      return;
    }
    
    try {
      final List<dynamic> questions = jsonDecode(questionsJson);
      final List<Map<String, dynamic>> repairedQuestions = [];
      
      for (int i = 0; i < questions.length; i++) {
        final question = Map<String, dynamic>.from(questions[i]);
        final originalQuestion = Map<String, dynamic>.from(question);
        
        // Repair missing categoryId field (CRITICAL for Supabase)
        if (!question.containsKey('categoryId') || question['categoryId'] == null) {
          final category = question['category'] as String?;
          if (category != null) {
            question['categoryId'] = _mapLegacyCategoryToCategoryId(category);
            result.addRepair('interview_questions[$i]', 'Added missing categoryId: ${question['categoryId']}');
          } else {
            question['categoryId'] = 'data_analysis'; // Safe default
            result.addRepair('interview_questions[$i]', 'Added default categoryId: data_analysis');
          }
        }
        
        // Repair boolean fields stored as strings
        final boolFields = ['isDraft', 'isStarred', 'isCompleted'];
        for (final field in boolFields) {
          if (question.containsKey(field)) {
            final value = question[field];
            if (value is String) {
              question[field] = value.toLowerCase() == 'true';
              result.addRepair('interview_questions[$i]', 'Fixed boolean field $field: "$value" -> ${question[field]}');
            } else if (value is! bool) {
              question[field] = false; // Safe default
              result.addRepair('interview_questions[$i]', 'Fixed invalid boolean field $field: $value -> false');
            }
          } else {
            question[field] = false; // Add missing boolean fields
            result.addRepair('interview_questions[$i]', 'Added missing boolean field $field: false');
          }
        }
        
        // Repair invalid difficulty values
        if (question.containsKey('difficulty')) {
          final difficulty = question['difficulty'] as String?;
          final validDifficulties = ['entry', 'mid', 'senior'];
          if (difficulty == null || !validDifficulties.contains(difficulty)) {
            question['difficulty'] = 'entry'; // Safe default
            result.addRepair('interview_questions[$i]', 'Fixed invalid difficulty: "$difficulty" -> "entry"');
          }
        } else {
          question['difficulty'] = 'entry';
          result.addRepair('interview_questions[$i]', 'Added missing difficulty field: entry');
        }
        
        // Ensure required string fields are present and non-empty
        final requiredStringFields = ['id', 'text', 'category', 'subtopic'];
        for (final field in requiredStringFields) {
          if (!question.containsKey(field) || question[field] == null || question[field].toString().isEmpty) {
            if (field == 'id') {
              question[field] = 'repair_${DateTime.now().millisecondsSinceEpoch}_$i';
            } else if (field == 'text') {
              question[field] = 'Question text needs to be added';
            } else if (field == 'category') {
              question[field] = 'technical';
            } else if (field == 'subtopic') {
              question[field] = 'General Knowledge';
            }
            result.addRepair('interview_questions[$i]', 'Fixed missing/empty field $field: ${question[field]}');
          }
        }
        
        repairedQuestions.add(question);
      }
      
      // Save repaired data
      final repairedJson = jsonEncode(repairedQuestions);
      await prefs.setString('interview_questions', repairedJson);
      result.addInfo('Successfully repaired ${repairedQuestions.length} interview questions');
      
    } catch (e) {
      result.addError('Failed to repair interview questions: $e');
    }
  }
  
  String _mapLegacyCategoryToCategoryId(String category) {
    final mapping = {
      'technical': 'data_analysis',
      'applied': 'machine_learning', 
      'behavioral': 'python',
      'case': 'statistics',
      'job': 'web_development',
    };
    return mapping[category] ?? 'data_analysis';
  }
  
  Future<void> _repairFlashcardSets(DataRepairResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = prefs.getStringList('flashcard_sets');
    
    if (setsJson == null || setsJson.isEmpty) {
      result.addInfo('No flashcard sets to repair');
      return;
    }
    
    final List<String> repairedSets = [];
    
    for (int i = 0; i < setsJson.length; i++) {
      try {
        final setData = Map<String, dynamic>.from(jsonDecode(setsJson[i]));
        
        // Ensure required fields exist
        if (!setData.containsKey('id') || setData['id'] == null) {
          setData['id'] = 'repair_set_${DateTime.now().millisecondsSinceEpoch}_$i';
          result.addRepair('flashcard_sets[$i]', 'Added missing id: ${setData['id']}');
        }
        
        if (!setData.containsKey('title') || setData['title'] == null || setData['title'].toString().isEmpty) {
          setData['title'] = 'Untitled Flashcard Set';
          result.addRepair('flashcard_sets[$i]', 'Added missing title');
        }
        
        if (!setData.containsKey('flashcards') || setData['flashcards'] is! List) {
          setData['flashcards'] = [];
          result.addRepair('flashcard_sets[$i]', 'Fixed missing/invalid flashcards array');
        }
        
        // Fix numeric fields
        if (setData.containsKey('rating') && setData['rating'] is! num) {
          setData['rating'] = 0.0;
          result.addRepair('flashcard_sets[$i]', 'Fixed invalid rating type');
        }
        
        if (setData.containsKey('ratingCount') && setData['ratingCount'] is! int) {
          setData['ratingCount'] = 0;
          result.addRepair('flashcard_sets[$i]', 'Fixed invalid ratingCount type');
        }
        
        // Ensure lastUpdated is valid ISO string
        if (!setData.containsKey('lastUpdated')) {
          setData['lastUpdated'] = DateTime.now().toIso8601String();
          result.addRepair('flashcard_sets[$i]', 'Added missing lastUpdated field');
        } else {
          try {
            DateTime.parse(setData['lastUpdated']);
          } catch (e) {
            setData['lastUpdated'] = DateTime.now().toIso8601String();
            result.addRepair('flashcard_sets[$i]', 'Fixed invalid lastUpdated format');
          }
        }
        
        repairedSets.add(jsonEncode(setData));
        
      } catch (e) {
        result.addError('Failed to repair flashcard set $i: $e');
        // Skip corrupted set rather than crash
        continue;
      }
    }
    
    // Save repaired data
    await prefs.setStringList('flashcard_sets', repairedSets);
    result.addInfo('Successfully repaired ${repairedSets.length} flashcard sets');
  }
  
  Future<void> _validateRepairs(DataRepairResult result) async {
    // Run validation again to ensure repairs worked
    final validationReport = await _validator.validateAllStoredData();
    
    result.postRepairValidation = validationReport;
    
    if (validationReport.hasBlockingIssues) {
      result.addError('Repairs did not resolve all blocking issues');
    } else {
      result.addInfo('All repairs successful - data is now migration-ready');
    }
  }
}

class DataRepairResult {
  final List<String> repairs = [];
  final List<String> errors = [];
  final List<String> info = [];
  DataValidationReport? postRepairValidation;
  
  void addRepair(String location, String description) {
    repairs.add('$location: $description');
  }
  
  void addError(String message) {
    errors.add(message);
  }
  
  void addInfo(String message) {
    info.add(message);
  }
  
  bool get wasSuccessful => errors.isEmpty && (postRepairValidation?.hasBlockingIssues != true);
  
  void printSummary() {
    print('=== DATA REPAIR SUMMARY ===');
    print('Repairs Applied: ${repairs.length}');
    print('Errors: ${errors.length}');
    print('Success: ${wasSuccessful ? 'YES' : 'NO'}');
    
    if (repairs.isNotEmpty) {
      print('\n🔧 REPAIRS APPLIED:');
      for (final repair in repairs) {
        print('  ✅ $repair');
      }
    }
    
    if (errors.isNotEmpty) {
      print('\n❌ ERRORS:');
      for (final error in errors) {
        print('  ❌ $error');
      }
    }
    
    if (info.isNotEmpty) {
      print('\n📋 INFO:');
      for (final item in info) {
        print('  ℹ️ $item');
      }
    }
  }
}
```

### Step 2: Add Repair Command to Debug Service
Update `lib/services/debug_service.dart`:

```dart
class DebugService {
  static Future<void> runDataRepair() async {
    print('Starting automated data repair...');
    
    final repairService = DataRepairService();
    final result = await repairService.repairAllData();
    
    result.printSummary();
    
    if (result.wasSuccessful) {
      print('\n✅ Data repair completed successfully');
      print('🚀 Ready to proceed with Supabase migration');
    } else {
      print('\n❌ Data repair encountered issues');
      print('⛔ Review errors before proceeding');
    }
  }
}
```

### Step 3: Create Repair UI Screen
Add repair functionality to `DataValidationScreen`:

```dart
// Add to _DataValidationScreenState class
Future<void> _runRepair() async {
  setState(() {
    _isRepairing = true;
  });
  
  try {
    final repairService = DataRepairService();
    final result = await repairService.repairAllData();
    
    // Show results
    _showRepairResults(result);
    
    // Re-run validation to show updated status
    await _runValidation();
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Repair failed: $e')),
    );
  } finally {
    setState(() {
      _isRepairing = false;
    });
  }
}

void _showRepairResults(DataRepairResult result) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(result.wasSuccessful ? 'Repair Successful' : 'Repair Issues'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Repairs Applied: ${result.repairs.length}'),
            Text('Errors: ${result.errors.length}'),
            if (result.repairs.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Repairs:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.repairs.take(5).map((repair) => Text('• $repair', style: TextStyle(fontSize: 12))),
              if (result.repairs.length > 5) Text('... and ${result.repairs.length - 5} more'),
            ],
            if (result.errors.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...result.errors.map((error) => Text('• $error', style: TextStyle(fontSize: 12, color: Colors.red))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## Acceptance Criteria

- [ ] All missing `categoryId` fields are automatically populated with correct mappings
- [ ] Boolean fields stored as strings are converted to proper boolean values
- [ ] Invalid difficulty enum values are corrected to valid options
- [ ] Missing required fields are populated with safe defaults
- [ ] Malformed JSON structures are either repaired or safely removed
- [ ] Post-repair validation confirms migration readiness
- [ ] Repair process includes comprehensive logging and error handling
- [ ] Backup is created before any repair operations
- [ ] UI provides clear feedback on repair operations

## Testing Instructions

1. **Run repair via debug console:**
   ```dart
   await DebugService.runDataRepair();
   ```

2. **Test repair through UI:**
   - Navigate to Data Validation screen
   - Run validation to identify issues
   - Tap "Repair Data" button
   - Review repair results dialog
   - Verify post-repair validation shows clean results

3. **Test with known corruption:**
   - Manually introduce data corruption
   - Run repair process
   - Confirm corruption is fixed appropriately

## Expected Repairs

Based on code analysis, expect to apply:
- 50-100 missing `categoryId` field repairs
- 20-30 boolean field type corrections
- 5-10 invalid difficulty value fixes
- 10-20 missing required field additions
- Various JSON structure normalizations

## Rollback Strategy

If repair fails:
1. Restore from backup created at start of repair process
2. Analyze specific failure points
3. Implement targeted fixes for failed repairs
4. Re-run repair process

## Next Steps
After completing this task:
- Proceed to Task 1.3: Migration Backup System
- Run comprehensive validation to confirm repairs
- Document repair patterns for future reference

## Dependencies
- Task 1.1 (Data Validation Service)
- `shared_preferences` package
- JSON encoding/decoding capabilities