# Authentication Integration Examples
## How to Add Authentication Gates to Existing Features

### 1. Basic Action Wrapping

Wrap any action that should respect usage limits:

```dart
// Before - Direct action
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => StudyScreen(flashcardSet: set)),
  ),
  child: Text('Study'),
)

// After - With authentication gate
AuthenticatedAction(
  actionType: 'flashcard_study_start',
  onAction: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => StudyScreen(flashcardSet: set)),
  ),
  child: ElevatedButton(
    onPressed: null, // Handled by AuthenticatedAction
    child: Text('Study'),
  ),
)
```

### 2. Flashcard Study Integration

In `screens/study_screen.dart`, track each flashcard flip:

```dart
// Add to existing FlashcardWidget onFlip callback
void _onFlashcardFlip() async {
  final usageGate = context.read<UsageGateService>();
  final canFlip = await usageGate.attemptAction(actionType: 'flashcard_flip');
  
  if (canFlip) {
    // Existing flip logic
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }
  // If can't flip, authentication popup will be shown automatically
}
```

### 3. Interview Practice Integration

In `screens/interview_questions_screen.dart`, track practice starts:

```dart
void _startInterviewPractice(InterviewQuestion question) async {
  final usageGate = context.read<UsageGateService>();
  final canStart = await usageGate.attemptAction(actionType: 'interview_practice_start');
  
  if (canStart) {
    // Existing practice logic
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InterviewPracticeScreen(question: question),
      ),
    );
  }
}
```

### 4. Debug Panel Integration

Add to any screen for testing (debug builds only):

```dart
// In scaffold body or as floating action button
if (kDebugMode)
  Positioned(
    top: 100,
    right: 16,
    child: AuthDebugPanel(),
  ),
```

### 5. Usage Status Display

Show remaining actions to users:

```dart
Consumer<UsageGateService>(
  builder: (context, usageGate, child) {
    if (!usageGate.isNearLimit()) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${usageGate.getRemainingActions()} actions remaining. Sign in to continue!',
        style: TextStyle(color: Colors.orange[800]),
      ),
    );
  },
),
```
