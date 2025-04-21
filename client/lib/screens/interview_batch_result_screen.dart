import 'package:flutter/material.dart';
import '../models/interview_answer.dart';
import '../utils/colors.dart';
import '../utils/design_system.dart';

class InterviewBatchResultScreen extends StatelessWidget {
  final List<InterviewAnswer> answers;
  final VoidCallback onContinue;

  const InterviewBatchResultScreen({
    super.key,
    required this.answers,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    // Filter answers to exclude empty ones
    final nonEmptyAnswers = answers.where((a) => a.userAnswer.trim().isNotEmpty).toList();
    
    // Calculate stats
    int totalAnswers = nonEmptyAnswers.length;
    int completedAnswers = nonEmptyAnswers.where((a) => (a.score ?? 0) >= 70).length;
    double averageScore = totalAnswers > 0 
        ? nonEmptyAnswers.fold(0, (sum, a) => sum + (a.score ?? 0)) / totalAnswers 
        : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Results'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onContinue,
        ),
      ),
      body: Column(
        children: [
          // Stats container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batch Assessment Results',
                  style: DS.headingMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Answers Graded',
                      totalAnswers.toString(),
                      Icons.question_answer,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Passing Answers',
                      completedAnswers.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Average Score',
                      averageScore.toStringAsFixed(1),
                      Icons.analytics,
                      _getColorForScore(averageScore.toInt()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results list
          Expanded(
            child: nonEmptyAnswers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: nonEmptyAnswers.length,
                    itemBuilder: (context, index) {
                      final answer = nonEmptyAnswers[index];
                      return _buildAnswerCard(answer, context);
                    },
                  ),
          ),
          
          // Continue button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Return to Questions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 13),
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(InterviewAnswer answer, BuildContext context) {
    final score = answer.score ?? 0;
    final Color scoreColor = _getColorForScore(score);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: scoreColor.withValues(
            red: scoreColor.r,
            green: scoreColor.g,
            blue: scoreColor.b,
            alpha: 77), // 0.3 * 255 ≈ 77
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(
                      red: scoreColor.r,
                      green: scoreColor.g,
                      blue: scoreColor.b,
                      alpha: 38), // 0.15 * 255 ≈ 38
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                // Question text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTruncatedText(answer.questionText, 100),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _getScoreLabel(score),
                        style: TextStyle(
                          fontSize: 14,
                          color: scoreColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Divider(),
            const SizedBox(height: 8.0),
            // Answer text
            Text(
              'Your Answer:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              _getTruncatedText(answer.userAnswer, 150),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12.0),
            // Feedback
            Text(
              'Feedback:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              _getTruncatedText(answer.feedback ?? 'No feedback available', 200),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16.0),
            // View details button
            Center(
              child: TextButton.icon(
                onPressed: () {
                  _showAnswerDetails(context, answer);
                },
                icon: const Icon(Icons.remove_red_eye),
                label: const Text('View Details'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No answers to grade',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'You need to provide at least one answer before submitting for grading.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAnswerDetails(BuildContext context, InterviewAnswer answer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16.0),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              
              // Title
              Text(
                'Answer Details',
                style: DS.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              
              // Question
              Text('Question:', style: DS.headingSmall),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  answer.questionText,
                  style: DS.bodyMedium,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Your answer
              Text('Your Answer:', style: DS.headingSmall),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  answer.userAnswer,
                  style: DS.bodyMedium,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Score
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getColorForScore(answer.score ?? 0).withValues(
                        red: _getColorForScore(answer.score ?? 0).r,
                        green: _getColorForScore(answer.score ?? 0).g,
                        blue: _getColorForScore(answer.score ?? 0).b,
                        alpha: 38), // 0.15 * 255 ≈ 38
                      border: Border.all(
                        color: _getColorForScore(answer.score ?? 0),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${answer.score ?? 0}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getColorForScore(answer.score ?? 0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Score',
                          style: DS.headingMedium,
                        ),
                        Text(
                          _getScoreLabel(answer.score ?? 0),
                          style: TextStyle(
                            fontSize: 16,
                            color: _getColorForScore(answer.score ?? 0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              
              // Feedback
              Text('Feedback:', style: DS.headingSmall),
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  answer.feedback ?? 'No feedback available.',
                  style: DS.bodyMedium,
                ),
              ),
              const SizedBox(height: 16.0),
              
              // Suggestions
              if (answer.suggestions != null && answer.suggestions!.isNotEmpty) ...[
                Text('Suggestions for Improvement:', style: DS.headingSmall),
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: answer.suggestions!.map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: DS.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              
              const SizedBox(height: 24.0),
              
              // Close button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForScore(int score) {
    if (score >= 90) return AppColors.gradeA;
    if (score >= 80) return AppColors.gradeB;
    if (score >= 70) return AppColors.gradeC;
    if (score >= 60) return AppColors.gradeD;
    return AppColors.gradeF;
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Satisfactory';
    if (score >= 60) return 'Needs Improvement';
    return 'Incomplete';
  }

  String _getTruncatedText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}