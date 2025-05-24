# Task 5.3: Replace Hardcoded Progress Values

## Objective

Replace hardcoded progress constants with dynamic progress calculation based on user data, implementing persistent progress tracking and customizable goal management.

## Current State Analysis

**Hardcoded Progress Issues in `home_screen.dart`:**
```dart
// Lines 50-51: Static progress values
int _weeklyGoal = 7;
int _daysCompleted = 5;

// Line 577: Static progress display
Text('Weekly Goal: $_daysCompleted/$_weeklyGoal days')
```

**Problems with Current Implementation:**
- Progress values don't reflect actual user activity
- Goals are fixed and cannot be customized by users
- No persistence of progress data across app sessions
- Limited progress tracking (only days completed)
- No analytics or progress history

## Implementation Approach

### Step 1: Create Progress Data Models

**Comprehensive Progress Model:**
```dart
// lib/models/progress_data.dart
class ProgressData {
  final String userId;
  final WeeklyProgress weeklyProgress;
  final OverallProgress overallProgress;
  final Map<String, CategoryProgress> categoryProgress;
  final List<DailyActivity> recentActivity;
  final ProgressGoals goals;
  final DateTime lastUpdated;
  
  ProgressData({
    required this.userId,
    required this.weeklyProgress,
    required this.overallProgress,
    required this.categoryProgress,
    required this.recentActivity,
    required this.goals,
    required this.lastUpdated,
  });
}

class WeeklyProgress {
  final int currentWeek;
  final int year;
  final int daysCompleted;
  final int questionsAnswered;
  final double averageScore;
  final Duration totalStudyTime;
  final List<bool> dailyCompletion; // 7 days, true if goal met
  
  WeeklyProgress({
    required this.currentWeek,
    required this.year,
    required this.daysCompleted,
    required this.questionsAnswered,
    required this.averageScore,
    required this.totalStudyTime,
    required this.dailyCompletion,
  });
  
  bool get weeklyGoalMet => daysCompleted >= ProgressGoals.defaultWeeklyGoal;
  double get weeklyCompletionRate => daysCompleted / ProgressGoals.defaultWeeklyGoal;
}

class OverallProgress {
  final int totalQuestionsAnswered;
  final int totalDaysActive;
  final double overallAverageScore;
  final Duration totalStudyTime;
  final int currentStreak;
  final int longestStreak;
  final DateTime firstActivity;
  final List<Achievement> achievements;
  
  OverallProgress({
    required this.totalQuestionsAnswered,
    required this.totalDaysActive,
    required this.overallAverageScore,
    required this.totalStudyTime,
    required this.currentStreak,
    required this.longestStreak,
    required this.firstActivity,
    required this.achievements,
  });
}

class CategoryProgress {
  final String categoryId;
  final int questionsAnswered;
  final double averageScore;
  final DateTime lastActivity;
  final int streak;
  final Duration timeSpent;
  final Map<String, double> topicScores;
  
  CategoryProgress({
    required this.categoryId,
    required this.questionsAnswered,
    required this.averageScore,
    required this.lastActivity,
    required this.streak,
    required this.timeSpent,
    required this.topicScores,
  });
}

class ProgressGoals {
  final int weeklyGoal;
  final int dailyQuestionGoal;
  final Duration dailyStudyTimeGoal;
  final double targetAccuracy;
  final Map<String, int> categoryGoals;
  
  static const int defaultWeeklyGoal = 7;
  static const int defaultDailyQuestionGoal = 5;
  static const Duration defaultDailyStudyTime = Duration(minutes: 30);
  static const double defaultTargetAccuracy = 0.80;
  
  ProgressGoals({
    required this.weeklyGoal,
    required this.dailyQuestionGoal,
    required this.dailyStudyTimeGoal,
    required this.targetAccuracy,
    required this.categoryGoals,
  });
  
  factory ProgressGoals.defaults() {
    return ProgressGoals(
      weeklyGoal: defaultWeeklyGoal,
      dailyQuestionGoal: defaultDailyQuestionGoal,
      dailyStudyTimeGoal: defaultDailyStudyTime,
      targetAccuracy: defaultTargetAccuracy,
      categoryGoals: {},
    );
  }
}
```

### Step 2: Create Progress Service

**Progress Tracking Service:**
```dart
// lib/services/progress_service.dart
class ProgressService {
  final DatabaseService _dbService;
  final CacheService _cacheService;
  
  ProgressService({
    required DatabaseService dbService,
    required CacheService cacheService,
  }) : _dbService = dbService, _cacheService = cacheService;
  
  Future<ProgressData> getUserProgress() async {
    try {
      // Check cache first
      final cachedProgress = await _cacheService.get<ProgressData>('user_progress');
      if (cachedProgress != null && !_isStale(cachedProgress.lastUpdated)) {
        return cachedProgress;
      }
      
      // Calculate current progress
      final progress = await _calculateProgress();
      
      // Cache the result
      await _cacheService.set('user_progress', progress, Duration(minutes: 15));
      
      return progress;
    } catch (e) {
      // Return default progress if calculation fails
      return _getDefaultProgress();
    }
  }
  
  Future<ProgressData> _calculateProgress() async {
    final userId = await _getUserId();
    final goals = await getProgressGoals(userId);
    
    // Calculate weekly progress
    final weeklyProgress = await _calculateWeeklyProgress(goals);
    
    // Calculate overall progress
    final overallProgress = await _calculateOverallProgress();
    
    // Calculate category progress
    final categoryProgress = await _calculateCategoryProgress();
    
    // Get recent activity
    final recentActivity = await _getRecentActivity(limit: 30);
    
    return ProgressData(
      userId: userId,
      weeklyProgress: weeklyProgress,
      overallProgress: overallProgress,
      categoryProgress: categoryProgress,
      recentActivity: recentActivity,
      goals: goals,
      lastUpdated: DateTime.now(),
    );
  }
  
  Future<WeeklyProgress> _calculateWeeklyProgress(ProgressGoals goals) async {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(Duration(days: 7));
    
    final activities = await _dbService.getActivitiesBetween(weekStart, weekEnd);
    
    // Calculate daily completion
    final dailyCompletion = List<bool>.filled(7, false);
    final dailyQuestionCounts = List<int>.filled(7, 0);
    
    for (final activity in activities) {
      final dayIndex = activity.date.difference(weekStart).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailyQuestionCounts[dayIndex] += activity.questionsAnswered;
        
        // Check if daily goal was met
        if (dailyQuestionCounts[dayIndex] >= goals.dailyQuestionGoal) {
          dailyCompletion[dayIndex] = true;
        }
      }
    }
    
    final daysCompleted = dailyCompletion.where((completed) => completed).length;
    final questionsAnswered = dailyQuestionCounts.fold(0, (sum, count) => sum + count);
    final averageScore = activities.isEmpty 
        ? 0.0 
        : activities.map((a) => a.score).reduce((a, b) => a + b) / activities.length;
    final totalStudyTime = activities.fold(
      Duration.zero, 
      (total, activity) => total + activity.duration,
    );
    
    return WeeklyProgress(
      currentWeek: _getWeekNumber(now),
      year: now.year,
      daysCompleted: daysCompleted,
      questionsAnswered: questionsAnswered,
      averageScore: averageScore,
      totalStudyTime: totalStudyTime,
      dailyCompletion: dailyCompletion,
    );
  }
  
  Future<void> recordActivity(ActivityRecord activity) async {
    await _dbService.saveActivity(activity);
    
    // Invalidate cache
    await _cacheService.remove('user_progress');
    
    // Check for achievements
    await _checkForAchievements(activity);
    
    // Update streaks
    await _updateStreaks();
  }
  
  Future<ProgressGoals> getProgressGoals(String userId) async {
    final savedGoals = await _dbService.getProgressGoals(userId);
    return savedGoals ?? ProgressGoals.defaults();
  }
  
  Future<void> updateProgressGoals(ProgressGoals goals) async {
    await _dbService.saveProgressGoals(goals);
    await _cacheService.remove('user_progress'); // Invalidate cache
  }
}
```

### Step 3: Update Home Screen with Dynamic Progress

**Dynamic Progress Widget:**
```dart
// lib/widgets/progress/weekly_progress_widget.dart
class WeeklyProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressService>(
      builder: (context, progressService, child) {
        return FutureBuilder<ProgressData>(
          future: progressService.getUserProgress(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error);
            }
            
            final progress = snapshot.data;
            if (progress == null) return _buildEmptyState();
            
            return _buildProgressDisplay(context, progress);
          },
        );
      },
    );
  }
  
  Widget _buildProgressDisplay(BuildContext context, ProgressData progress) {
    final weeklyProgress = progress.weeklyProgress;
    final goals = progress.goals;
    
    return Container(
      padding: context.cardPadding,
      decoration: ThemedComponents.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly goal header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).weeklyGoal,
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildGoalSettingsButton(context),
            ],
          ),
          
          SizedBox(height: DS.spacingM),
          
          // Progress text with dynamic values
          Text(
            AppLocalizations.of(context).weeklyGoalProgress(
              weeklyProgress.daysCompleted,
              goals.weeklyGoal,
            ),
            style: context.bodyLarge?.copyWith(
              color: AppColors.getTextPrimary(context.isDarkMode),
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: DS.spacingM),
          
          // Progress indicator
          LinearProgressIndicator(
            value: weeklyProgress.weeklyCompletionRate,
            backgroundColor: context.isDarkMode 
                ? Colors.grey.shade700 
                : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getProgressColor(weeklyProgress.weeklyCompletionRate, context),
            ),
          ),
          
          SizedBox(height: DS.spacingM),
          
          // Daily completion indicators
          _buildDailyCompletionIndicators(context, weeklyProgress),
          
          if (weeklyProgress.questionsAnswered > 0) ...[
            SizedBox(height: DS.spacingM),
            _buildAdditionalStats(context, weeklyProgress),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDailyCompletionIndicators(BuildContext context, WeeklyProgress progress) {
    final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isCompleted = progress.dailyCompletion[index];
        final isToday = _isToday(index);
        
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? context.primaryColor 
                : context.isDarkMode 
                    ? Colors.grey.shade700 
                    : Colors.grey.shade300,
            border: isToday 
                ? Border.all(color: context.primaryColor, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              days[index],
              style: context.labelMedium?.copyWith(
                color: isCompleted 
                    ? Colors.white 
                    : AppColors.getTextSecondary(context.isDarkMode),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
  
  Color _getProgressColor(double completionRate, BuildContext context) {
    if (completionRate >= 1.0) return context.successColor;
    if (completionRate >= 0.7) return context.primaryColor;
    if (completionRate >= 0.4) return context.warningColor;
    return context.errorColor;
  }
}
```

### Step 4: Goal Customization Interface

**Goal Settings Screen:**
```dart
// lib/screens/goals_settings_screen.dart
class GoalsSettingsScreen extends StatefulWidget {
  @override
  _GoalsSettingsScreenState createState() => _GoalsSettingsScreenState();
}

class _GoalsSettingsScreenState extends State<GoalsSettingsScreen> {
  late ProgressGoals _currentGoals;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }
  
  Future<void> _loadCurrentGoals() async {
    final progressService = Provider.of<ProgressService>(context, listen: false);
    final userId = await AuthService.getCurrentUserId();
    _currentGoals = await progressService.getProgressGoals(userId);
    
    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).goalSettings)),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).goalSettings),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _saveGoals,
              child: Text(AppLocalizations.of(context).save),
            ),
        ],
      ),
      body: ListView(
        padding: context.screenPadding,
        children: [
          _buildWeeklyGoalSetting(),
          SizedBox(height: DS.spacingL),
          _buildDailyGoalSetting(),
          SizedBox(height: DS.spacingL),
          _buildStudyTimeGoalSetting(),
          SizedBox(height: DS.spacingL),
          _buildAccuracyGoalSetting(),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyGoalSetting() {
    return Container(
      padding: context.cardPadding,
      decoration: ThemedComponents.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).weeklyGoalSetting,
            style: context.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: DS.spacingS),
          Text(
            AppLocalizations.of(context).weeklyGoalDescription,
            style: context.bodyMedium?.copyWith(
              color: AppColors.getTextSecondary(context.isDarkMode),
            ),
          ),
          SizedBox(height: DS.spacingM),
          Slider(
            value: _currentGoals.weeklyGoal.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            label: AppLocalizations.of(context).daysCount(_currentGoals.weeklyGoal),
            onChanged: (value) {
              setState(() {
                _currentGoals = _currentGoals.copyWith(weeklyGoal: value.round());
                _hasChanges = true;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveGoals() async {
    final progressService = Provider.of<ProgressService>(context, listen: false);
    await progressService.updateProgressGoals(_currentGoals);
    
    setState(() {
      _hasChanges = false;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).goalsSaved),
        backgroundColor: context.successColor,
      ),
    );
  }
}
```

## Testing Strategy

**Unit Tests:**
```dart
// test/services/progress_service_test.dart
group('ProgressService Tests', () {
  testWidgets('calculates weekly progress correctly', (tester) async {
    final mockDbService = MockDatabaseService();
    final mockCacheService = MockCacheService();
    
    when(mockDbService.getActivitiesBetween(any, any))
        .thenAnswer((_) async => [
          ActivityRecord(date: DateTime.now(), questionsAnswered: 5, score: 0.8),
          ActivityRecord(date: DateTime.now().subtract(Duration(days: 1)), questionsAnswered: 3, score: 0.9),
        ]);
    
    final service = ProgressService(
      dbService: mockDbService,
      cacheService: mockCacheService,
    );
    
    final progress = await service.getUserProgress();
    
    expect(progress.weeklyProgress.questionsAnswered, 8);
    expect(progress.weeklyProgress.daysCompleted, 2);
    expect(progress.weeklyProgress.averageScore, 0.85);
  });
});
```

## Performance Considerations

**Caching Strategy:**
- Cache progress calculations for 15 minutes
- Use background refresh to update stale data
- Implement incremental updates for activity records
- Cache goal settings until explicitly changed

**Database Optimization:**
- Index activity records by date and user
- Use aggregation queries for progress calculations
- Implement data archiving for old activity records
- Optimize queries with proper pagination

## Success Criteria

- [ ] All hardcoded progress values replaced with dynamic calculations
- [ ] Progress data accurately reflects user activity
- [ ] Goals can be customized and persisted across sessions
- [ ] Progress calculations are performant and cached appropriately
- [ ] Weekly and daily progress tracking works correctly
- [ ] Visual progress indicators update dynamically
- [ ] Goal settings interface is intuitive and functional

## Next Steps

After completing Task 5.3, proceed to:
1. **Task 5.4**: Update mock flashcards to use dynamic data providers
2. **Task 5.5**: Create comprehensive testing utilities for data management
