import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your app's modules
import 'package:flutter_flashcard_app/models/simple_auth_state.dart';
import 'package:flutter_flashcard_app/providers/working_action_tracking_provider.dart';
import 'package:flutter_flashcard_app/services/usage_limit_enforcer.dart';
import 'package:flutter_flashcard_app/services/action_middleware.dart';
import 'package:flutter_flashcard_app/utils/config.dart';

void main() {
  group('Combined Usage Limit Enforcement Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Enable usage limits for testing
      AuthConfig.enableUsageLimits = true;
      AuthConfig.guestMaxGradingActions = 3;
      AuthConfig.authenticatedMaxGradingActions = 5;
      
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Guest user quota enforcement across features', (tester) async {
      final enforcer = container.read(usageLimitEnforcerProvider);

      // Initially should be able to perform actions
      expect(enforcer.canPerformAnyAction(), true);
      expect(enforcer.getRemainingActions(), 3);

      // Simulate 2 flashcard grading actions
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);

      // Should have 1 action remaining
      expect(enforcer.getRemainingActions(), 1);
      expect(enforcer.canPerformAnyAction(), true);

      // 3rd action (interview practice) should still be allowed
      final canProceedInterview = await enforcer.enforceLimit(
        ActionType.interviewPractice,
        source: 'test',
      );
      expect(canProceedInterview, true);

      // Record the 3rd action
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.interviewPractice);

      // Now should be at limit
      expect(enforcer.getRemainingActions(), 0);
      expect(enforcer.canPerformAnyAction(), false);

      // 4th action should be blocked regardless of type
      final canProceedFlashcard = await enforcer.enforceLimit(
        ActionType.flashcardGrading,
        source: 'test',
      );
      expect(canProceedFlashcard, false);

      final canProceedInterview2 = await enforcer.enforceLimit(
        ActionType.interviewPractice,
        source: 'test',
      );
      expect(canProceedInterview2, false);
    });

    testWidgets('Usage summary shows combined totals', (tester) async {
      final enforcer = container.read(usageLimitEnforcerProvider);

      // Record mixed actions
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.interviewPractice);

      final summary = enforcer.getUsageSummary();
      
      expect(summary['totalUsed'], 2);
      expect(summary['maxActions'], 3);
      expect(summary['remaining'], 1);
      expect(summary['canPerform'], true);
      expect(summary['authenticated'], false);
    });

    testWidgets('Action middleware enforces limits correctly', (tester) async {
      final middleware = container.read(actionMiddlewareProvider);

      // Execute actions through middleware
      final result1 = await middleware.executeWithQuota(
        ActionType.flashcardGrading,
        () async => 'flashcard_result_1',
        source: 'test',
      );
      expect(result1, 'flashcard_result_1');

      final result2 = await middleware.executeWithQuota(
        ActionType.interviewPractice,
        () async => 'interview_result_1',
        source: 'test',
      );
      expect(result2, 'interview_result_1');

      final result3 = await middleware.executeWithQuota(
        ActionType.flashcardGrading,
        () async => 'flashcard_result_2',
        source: 'test',
      );
      expect(result3, 'flashcard_result_2');

      // 4th action should be blocked
      final result4 = await middleware.executeWithQuota(
        ActionType.interviewPractice,
        () async => 'interview_result_2',
        source: 'test',
      );
      expect(result4, null);

      // Verify usage
      final summary = middleware.getUsageSummary();
      expect(summary['totalUsed'], 3);
      expect(summary['remaining'], 0);
    });

    testWidgets('Cross-feature consistency test', (tester) async {
      // This test simulates the exact scenario from the bug report
      final enforcer = container.read(usageLimitEnforcerProvider);

      // User completes 3 flashcard grading actions
      for (int i = 0; i < 3; i++) {
        final canProceed = await enforcer.enforceLimit(
          ActionType.flashcardGrading,
          source: 'StudyBloc',
        );
        expect(canProceed, true, reason: 'Flashcard action ${i + 1} should be allowed');
        
        await container.read(actionTrackerProvider.notifier)
            .recordAction(ActionType.flashcardGrading);
      }

      // Verify we're at the limit
      expect(enforcer.canPerformAnyAction(), false);
      expect(enforcer.getRemainingActions(), 0);

      // Attempt interview practice (this should be blocked)
      final canProceedInterview = await enforcer.enforceLimit(
        ActionType.interviewPractice,
        source: 'InterviewApiService',
      );
      expect(canProceedInterview, false, reason: 'Interview practice should be blocked after 3 flashcard actions');
    });

    testWidgets('Usage summary accuracy test', (tester) async {
      final enforcer = container.read(usageLimitEnforcerProvider);
      
      // Start with clean state
      final initialSummary = enforcer.getUsageSummary();
      expect(initialSummary['totalUsed'], 0);
      expect(initialSummary['maxActions'], 3);
      expect(initialSummary['remaining'], 3);
      
      // Add one action
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      
      final afterOneSummary = enforcer.getUsageSummary();
      expect(afterOneSummary['totalUsed'], 1);
      expect(afterOneSummary['remaining'], 2);
      expect(afterOneSummary['canPerform'], true);
      
      // Add two more actions
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.interviewPractice);
      await container.read(actionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      
      final afterThreeSummary = enforcer.getUsageSummary();
      expect(afterThreeSummary['totalUsed'], 3);
      expect(afterThreeSummary['remaining'], 0);
      expect(afterThreeSummary['canPerform'], false);
    });
  });
}
