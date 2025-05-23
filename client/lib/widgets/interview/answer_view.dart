import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/interview_question.dart';
import '../../utils/design_system.dart';
import '../../utils/colors.dart';
import '../../utils/theme_utils.dart';

class AnswerView extends StatelessWidget {
  final InterviewQuestion question;
  final VoidCallback onMarkComplete;
  final VoidCallback onClose;

  const AnswerView({
    super.key,
    required this.question,
    required this.onMarkComplete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Since we don't have actual answers in our model yet,
    // we'll just generate a mock answer
    final String mockAnswer = _generateMockAnswer(question);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF2A2A30) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DS.borderRadiusSmall),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DS.spacingM,
              vertical: DS.spacingS,
            ),
            decoration: BoxDecoration(
              color:
                  context.isDarkMode
                      ? context.primaryColor.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DS.borderRadiusSmall),
                topRight: Radius.circular(DS.borderRadiusSmall),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.question_answer,
                  size: 20,
                  color:
                      context.isDarkMode
                          ? AppColors.primaryDark
                          : AppColors.primary,
                ),
                const SizedBox(width: DS.spacingXs),
                Text(
                  AppLocalizations.of(context).answerTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        context.isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color:
                        context.isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Question
          Container(
            padding: const EdgeInsets.all(DS.spacingM),
            decoration: BoxDecoration(
              color:
                  context.isDarkMode
                      ? Colors.grey.shade900.withValues(alpha: 0.7)
                      : Colors.grey.shade50,
            ),
            child: Text(
              question.text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color:
                    context.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
          ),

          Divider(
            height: 1,
            color:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
          ),

          // Answer
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DS.spacingM),
              child: Text(
                mockAnswer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color:
                      context.isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ),

          Divider(
            height: 1,
            color:
                context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(DS.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        context.isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade700,
                    side: BorderSide(
                      color:
                          context.isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DS.spacingM,
                      vertical: DS.spacingS,
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).close),
                ),
                const SizedBox(width: DS.spacingS),
                ElevatedButton(
                  onPressed: onMarkComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        context.isDarkMode
                            ? AppColors.primaryDark
                            : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DS.spacingM,
                      vertical: DS.spacingS,
                    ),
                  ),
                  child: Text(
                    question.isCompleted
                        ? AppLocalizations.of(context).markAsIncomplete
                        : AppLocalizations.of(context).markAsCompleteButton,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Generate a mock answer based on the question
  String _generateMockAnswer(InterviewQuestion question) {
    switch (question.id) {
      case '1':
        return 'Bias and variance are two key sources of error in machine learning models:\n\n'
            '1. Bias refers to the error introduced by approximating a real-world problem with a simplified model. High bias models tend to underfit the data, missing relevant patterns. Examples of high-bias models include linear regression when the true relationship is non-linear.\n\n'
            '2. Variance refers to the model\'s sensitivity to fluctuations in the training data. High variance models tend to overfit, learning the noise in the training data rather than the underlying pattern. Complex models like deep neural networks can exhibit high variance if not properly regularized.\n\n'
            'The bias-variance tradeoff is fundamental in machine learning - as you decrease bias, variance typically increases and vice versa. The optimal model finds the right balance for a given problem.';

      case '2':
        return 'Handling missing data in a dataset requires a systematic approach:\n\n'
            '1. Identify missing data patterns: Determine if data is missing completely at random (MCAR), missing at random (MAR), or missing not at random (MNAR).\n\n'
            '2. Evaluate the extent of missing data: Calculate the percentage of missing values per column. If a column has too many missing values (e.g., >50%), consider dropping it.\n\n'
            '3. Choose an appropriate imputation strategy:\n'
            '   - For numerical data: Mean, median, mode imputation, KNN imputation, or regression imputation\n'
            '   - For categorical data: Mode imputation, dummy variable for missingness, or prediction-based imputation\n'
            '   - Advanced techniques: Multiple imputation or algorithms that handle missing values (e.g., XGBoost)\n\n'
            '4. Document your approach and validate: Always document your missing data handling strategy and evaluate its impact on model performance.';

      case '3':
        return 'When explaining complex technical findings to non-technical stakeholders, I follow these steps:\n\n'
            '1. Understand the audience\'s background and interests: Tailor the explanation to their knowledge level and focus on what matters to them.\n\n'
            '2. Start with the business impact: Begin with the "why" - explain the business implications of the findings before diving into technical details.\n\n'
            '3. Use analogies and visual aids: Translate complex concepts into familiar analogies and use clear visualizations to convey patterns.\n\n'
            '4. Avoid jargon: Replace technical terms with plain language when possible, or define them clearly when they\'re necessary.\n\n'
            '5. Create a narrative: Structure the presentation as a story with a clear flow, focusing on the problem, approach, and solution.\n\n'
            '6. Provide different levels of detail: Prepare a high-level summary with the option to dive deeper into specific areas based on interest.\n\n'
            '7. Check for understanding: Pause regularly to ensure the audience is following and address any questions or misconceptions.';

      case '4':
        return 'For evaluating classification models with imbalanced data, standard metrics like accuracy can be misleading. Instead, use:\n\n'
            '1. Confusion Matrix: Provides a complete picture of true positives, false positives, true negatives, and false negatives.\n\n'
            '2. Precision: TP/(TP+FP) - Measures how many of the positive predictions are actually correct.\n\n'
            '3. Recall (Sensitivity): TP/(TP+FN) - Measures how many of the actual positives were correctly identified.\n\n'
            '4. F1-Score: Harmonic mean of precision and recall, providing a balance between the two.\n\n'
            '5. Precision-Recall AUC: Area under the precision-recall curve, particularly useful for imbalanced datasets.\n\n'
            '6. ROC AUC: Area under the ROC curve, showing the model\'s ability to discriminate between classes.\n\n'
            '7. Balanced Accuracy: Average of sensitivity and specificity, accounting for class imbalance.\n\n'
            '8. Cohen\'s Kappa: Measures agreement between predicted and actual classifications, accounting for chance.\n\n'
            'The choice of metric depends on the specific problem and the relative cost of false positives versus false negatives.';

      case '5':
        return 'SQL query to find the top 5 customers by transaction value in the past month:\n\n'
            '```sql\n'
            'SELECT \n'
            '    c.customer_id,\n'
            '    c.first_name,\n'
            '    c.last_name,\n'
            '    SUM(t.amount) AS total_transaction_value\n'
            'FROM \n'
            '    customers c\n'
            'JOIN \n'
            '    transactions t ON c.customer_id = t.customer_id\n'
            'WHERE \n'
            '    t.transaction_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)\n'
            'GROUP BY \n'
            '    c.customer_id, c.first_name, c.last_name\n'
            'ORDER BY \n'
            '    total_transaction_value DESC\n'
            'LIMIT 5;\n'
            '```\n\n'
            'This query:\n'
            '1. Joins the customers and transactions tables\n'
            '2. Filters transactions from the past month using DATE_SUB\n'
            '3. Groups by customer and calculates the sum of transaction amounts\n'
            '4. Orders by the total value in descending order\n'
            '5. Limits to the top 5 results';

      case '6':
        return 'Designing a recommendation system for an e-commerce platform involves multiple components:\n\n'
            '**Features to use:**\n\n'
            '1. User-based features:\n'
            '   - Demographic information (age, location, gender if available)\n'
            '   - Browsing history and session data\n'
            '   - Purchase history and frequency\n'
            '   - Product ratings and reviews\n'
            '   - Wish list items\n'
            '   - Cart abandonment data\n'
            '   - Time spent on product pages\n\n'
            '2. Item-based features:\n'
            '   - Product categories and subcategories\n'
            '   - Product attributes (size, color, brand, price range)\n'
            '   - Product description embeddings\n'
            '   - Product popularity and trends\n'
            '   - Seasonal relevance\n'
            '   - Complementary and substitute relationships\n\n'
            '3. Contextual features:\n'
            '   - Time of day/week/year\n'
            '   - Device type\n'
            '   - Current location\n'
            '   - Special events or holidays\n\n'
            '**Recommendation approaches:**\n\n'
            '1. Collaborative filtering:\n'
            '   - User-based: "Customers who are similar to you also bought..."\n'
            '   - Item-based: "Customers who bought this item also bought..."\n\n'
            '2. Content-based filtering:\n'
            '   - Using product attributes and descriptions to recommend similar items\n\n'
            '3. Hybrid approaches:\n'
            '   - Combining collaborative and content-based methods for more robust recommendations\n\n'
            '4. Deep learning approaches:\n'
            '   - Neural networks for learning complex user-item interactions\n'
            '   - Sequence models for capturing temporal patterns\n\n'
            '**Implementation considerations:**\n'
            '- Cold start problem handling for new users/items\n'
            '- Real-time vs. batch recommendations\n'
            '- Diversity and serendipity in recommendations\n'
            '- A/B testing framework for continuous improvement\n'
            '- Ethical considerations and explainability';

      default:
        return 'This is a sample answer for the interview question. A complete answer would include key concepts, examples, and practical applications related to the question. For technical questions, explanations would include theory, implementation details, and common pitfalls. For behavioral questions, structured responses using the STAR method (Situation, Task, Action, Result) are recommended.';
    }
  }
}
