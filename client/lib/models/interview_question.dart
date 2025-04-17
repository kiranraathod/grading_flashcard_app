class InterviewQuestion {
  final String id;
  final String text;
  final String category; // technical, applied, case, behavioral, job
  final String subtopic;
  final String difficulty; // entry, mid, senior
  final String? answer; // Answer content
  bool isStarred;
  bool isCompleted;
  bool isDraft; // Whether this is a draft or published question
  
  InterviewQuestion({
    required this.id,
    required this.text,
    required this.category,
    required this.subtopic,
    required this.difficulty,
    this.answer,
    this.isStarred = false,
    this.isCompleted = false,
    this.isDraft = false,
  });
  
  InterviewQuestion copyWith({
    String? id,
    String? text,
    String? category,
    String? subtopic,
    String? difficulty,
    String? answer,
    bool? isStarred,
    bool? isCompleted,
    bool? isDraft,
  }) {
    return InterviewQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      subtopic: subtopic ?? this.subtopic,
      difficulty: difficulty ?? this.difficulty,
      answer: answer ?? this.answer,
      isStarred: isStarred ?? this.isStarred,
      isCompleted: isCompleted ?? this.isCompleted,
      isDraft: isDraft ?? this.isDraft,
    );
  }
  
  // Mock data for testing
  static List<InterviewQuestion> getMockQuestions() {
    return [
      InterviewQuestion(
        id: '1',
        text: 'Explain the difference between bias and variance in machine learning models.',
        category: 'technical',
        subtopic: 'Machine Learning Algorithms',
        difficulty: 'mid',
        isStarred: true,
        answer: 'Bias and variance are two key sources of error in machine learning models:\n\n'
            '1. **Bias** refers to the error introduced by approximating a real-world problem with a simplified model. High bias models tend to underfit the data, missing relevant patterns. Examples of high-bias models include linear regression when the true relationship is non-linear.\n\n'
            '2. **Variance** refers to the model\'s sensitivity to fluctuations in the training data. High variance models tend to overfit, learning the noise in the training data rather than the underlying pattern. Complex models like deep neural networks can exhibit high variance if not properly regularized.\n\n'
            'The bias-variance tradeoff is fundamental in machine learning - as you decrease bias, variance typically increases and vice versa. The optimal model finds the right balance for a given problem.',
      ),
      InterviewQuestion(
        id: '2',
        text: 'How would you handle missing data in a dataset?',
        category: 'applied',
        subtopic: 'Data Cleaning & Preprocessing',
        difficulty: 'entry',
        answer: 'Handling missing data in a dataset requires a systematic approach:\n\n'
            '1. **Identify missing data patterns**: Determine if data is missing completely at random (MCAR), missing at random (MAR), or missing not at random (MNAR).\n\n'
            '2. **Evaluate the extent of missing data**: Calculate the percentage of missing values per column. If a column has too many missing values (e.g., >50%), consider dropping it.\n\n'
            '3. **Choose an appropriate imputation strategy**:\n'
            '   - For numerical data: Mean, median, mode imputation, KNN imputation, or regression imputation\n'
            '   - For categorical data: Mode imputation, dummy variable for missingness, or prediction-based imputation\n'
            '   - Advanced techniques: Multiple imputation or algorithms that handle missing values (e.g., XGBoost)\n\n'
            '4. **Document your approach and validate**: Always document your missing data handling strategy and evaluate its impact on model performance.',
      ),
      InterviewQuestion(
        id: '3',
        text: 'Describe a situation where you had to explain complex technical findings to non-technical stakeholders.',
        category: 'behavioral',
        subtopic: 'Communication Skills',
        difficulty: 'mid',
        isStarred: true,
        answer: 'When explaining complex technical findings to non-technical stakeholders, I follow these steps:\n\n'
            '1. **Understand the audience\'s background and interests**: Tailor the explanation to their knowledge level and focus on what matters to them.\n\n'
            '2. **Start with the business impact**: Begin with the "why" - explain the business implications of the findings before diving into technical details.\n\n'
            '3. **Use analogies and visual aids**: Translate complex concepts into familiar analogies and use clear visualizations to convey patterns.\n\n'
            '4. **Avoid jargon**: Replace technical terms with plain language when possible, or define them clearly when they\'re necessary.\n\n'
            '5. **Create a narrative**: Structure the presentation as a story with a clear flow, focusing on the problem, approach, and solution.\n\n'
            '6. **Provide different levels of detail**: Prepare a high-level summary with the option to dive deeper into specific areas based on interest.\n\n'
            '7. **Check for understanding**: Pause regularly to ensure the audience is following and address any questions or misconceptions.',
      ),
      InterviewQuestion(
        id: '4',
        text: 'What metrics would you use to evaluate a classification model for imbalanced data?',
        category: 'applied',
        subtopic: 'Model Evaluation',
        difficulty: 'mid',
        answer: 'For evaluating classification models with imbalanced data, standard metrics like accuracy can be misleading. Instead, use:\n\n'
            '1. **Confusion Matrix**: Provides a complete picture of true positives, false positives, true negatives, and false negatives.\n\n'
            '2. **Precision**: TP/(TP+FP) - Measures how many of the positive predictions are actually correct.\n\n'
            '3. **Recall (Sensitivity)**: TP/(TP+FN) - Measures how many of the actual positives were correctly identified.\n\n'
            '4. **F1-Score**: Harmonic mean of precision and recall, providing a balance between the two.\n\n'
            '5. **Precision-Recall AUC**: Area under the precision-recall curve, particularly useful for imbalanced datasets.\n\n'
            '6. **ROC AUC**: Area under the ROC curve, showing the model\'s ability to discriminate between classes.\n\n'
            '7. **Balanced Accuracy**: Average of sensitivity and specificity, accounting for class imbalance.\n\n'
            '8. **Cohen\'s Kappa**: Measures agreement between predicted and actual classifications, accounting for chance.\n\n'
            'The choice of metric depends on the specific problem and the relative cost of false positives versus false negatives.',
      ),
      InterviewQuestion(
        id: '5',
        text: 'Write a SQL query to find the top 5 customers by transaction value in the past month.',
        category: 'technical',
        subtopic: 'SQL & Database',
        difficulty: 'entry',
        answer: 'SQL query to find the top 5 customers by transaction value in the past month:\n\n'
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
            '5. Limits to the top 5 results',
      ),
      InterviewQuestion(
        id: '6',
        text: 'Design a recommendation system for an e-commerce platform. What features would you use?',
        category: 'case',
        subtopic: 'Model Building Scenarios',
        difficulty: 'senior',
        isStarred: true,
        answer: 'Designing a recommendation system for an e-commerce platform involves multiple components:\n\n'
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
            '- Ethical considerations and explainability',
      ),
      // Draft question example
      InterviewQuestion(
        id: '7',
        text: 'Explain the concept of regularization in machine learning.',
        category: 'technical',
        subtopic: 'Machine Learning Algorithms',
        difficulty: 'mid',
        answer: 'Regularization is a technique used to prevent overfitting in machine learning models by adding a penalty term to the loss function.',
        isDraft: true,
      ),
    ];
  }
}