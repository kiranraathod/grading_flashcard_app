import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your app's modules
import 'package:flutter_flashcard_app/models/simple_auth_state.dart';
import 'package:flutter_flashcard_app/providers/unified_action_tracking_provider.dart';
import 'package:flutter_flashcard_app/services/unified_usage_limit_enforcer.dart';
import 'package:flutter_flashcard_app/services/unified_action_middleware.dart';
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
      final enforcer = container.read(unifiedUsageLimitEnforcerProvider);

      // Initially should be able to perform actions
      expect(enforcer.canPerformAnyAction(), true);
      expect(enforcer.getTotalRemainingActions(), 3);

      // Simulate 2 flashcard grading actions
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);

      // Should have 1 action remaining
      expect(enforcer.getTotalRemainingActions(), 1);
      expect(enforcer.canPerformAnyAction(), true);

      // 3rd action (interview practice) should still be allowed
      final canProceedInterview = await enforcer.enforceLimit(
        ActionType.interviewPractice,
        source: 'test',
      );
      expect(canProceedInterview, true);

      // Record the 3rd action
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.interviewPractice);

      // Now should be at limit
      expect(enforcer.getTotalRemainingActions(), 0);
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
      final enforcer = container.read(unifiedUsageLimitEnforcerProvider);

      // Record mixed actions
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.interviewPractice);

      final summary = enforcer.getUsageSummary();
      
      expect(summary['totalUsage'], 2);
      expect(summary['totalLimit'], 3);
      expect(summary['totalRemaining'], 1);
      expect(summary['canPerformAny'], true);
      expect(summary['authenticated'], false);
    });

    testWidgets('Action middleware enforces limits correctly', (tester) async {
      final middleware = container.read(unifiedActionMiddlewareProvider);

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
      expect(summary['totalUsage'], 3);
      expect(summary['totalRemaining'], 0);
    });

    testWidgets('Cross-feature consistency test', (tester) async {
      // This test simulates the exact scenario from the bug report
      final enforcer = container.read(unifiedUsageLimitEnforcerProvider);

      // User completes 3 flashcard grading actions
      for (int i = 0; i < 3; i++) {
        final canProceed = await enforcer.enforceLimit(
          ActionType.flashcardGrading,
          source: 'StudyBloc',
        );
        expect(canProceed, true, reason: 'Flashcard action ${i + 1} should be allowed');
        
        await container.read(unifiedActionTrackerProvider.notifier)
            .recordAction(ActionType.flashcardGrading);
      }

      // Verify we're at the limit
      expect(enforcer.canPerformAnyAction(), false);
      expect(enforcer.getTotalRemainingActions(), 0);

      // Attempt interview practice (this should be blocked)
      final canProceedInterview = await enforcer.enforceLimit(
        ActionType.interviewPractice,
        source: 'InterviewApiService',
      );
      expect(canProceedInterview, false, reason: 'Interview practice should be blocked after 3 flashcard actions');
    });

    testWidgets('Usage summary accuracy test', (tester) async {
      final enforcer = container.read(unifiedUsageLimitEnforcerProvider);
      
      // Start with clean state
      final initialSummary = enforcer.getUsageSummary();
      expect(initialSummary['totalUsage'], 0);
      expect(initialSummary['totalLimit'], 3);
      expect(initialSummary['totalRemaining'], 3);
      
      // Add one action
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      
      final afterOneSummary = enforcer.getUsageSummary();
      expect(afterOneSummary['totalUsage'], 1);
      expect(afterOneSummary['totalRemaining'], 2);
      expect(afterOneSummary['canPerformAny'], true);
      
      // Add two more actions
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.interviewPractice);
      await container.read(unifiedActionTrackerProvider.notifier)
          .recordAction(ActionType.flashcardGrading);
      
      final afterThreeSummary = enforcer.getUsageSummary();
      expect(afterThreeSummary['totalUsage'], 3);
      expect(afterThreeSummary['totalRemaining'], 0);
      expect(afterThreeSummary['canPerformAny'], false);
    });
  });
}
