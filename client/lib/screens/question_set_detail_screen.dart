import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../utils/theme_utils.dart';

class QuestionSetDetailScreen extends StatefulWidget {
  final String setId;

  const QuestionSetDetailScreen({super.key, required this.setId});

  @override
  State<QuestionSetDetailScreen> createState() => _QuestionSetDetailScreenState();
}

class _QuestionSetDetailScreenState extends State<QuestionSetDetailScreen> {
  late InterviewService _interviewService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);
  }

  // Edit question in a modal dialog
  void _editQuestion(InterviewQuestion question) {
    // Show a dialog to edit the question
    TextEditingController questionTextController = TextEditingController(text: question.text);
    TextEditingController subtopicController = TextEditingController(text: question.subtopic);
    TextEditingController answerController = TextEditingController(text: question.answer ?? '');
    
    // Keep track of the original category and difficulty
    String category = question.category;
    String difficulty = question.difficulty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Edit Question',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Text', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: questionTextController,
                maxLines: 3,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter question text',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Category', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: category,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'technical', 
                    child: Text(
                      'Technical Knowledge',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'applied', 
                    child: Text(
                      'Applied Skills',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'behavioral', 
                    child: Text(
                      'Behavioral Questions',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'case', 
                    child: Text(
                      'Case Study',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'job', 
                    child: Text(
                      'Job-Specific',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    category = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              
              Text(
                'Subtopic', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: subtopicController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter subtopic',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Difficulty', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: difficulty,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'entry', 
                    child: Text(
                      'Entry Level',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'mid', 
                    child: Text(
                      'Mid Level',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'senior', 
                    child: Text(
                      'Senior Level',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    difficulty = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              
              Text(
                'Example Answer', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: answerController,
                maxLines: 5,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter example answer',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update the question
              final updatedQuestion = question.copyWith(
                text: questionTextController.text,
                category: category,
                subtopic: subtopicController.text,
                difficulty: difficulty,
                answer: answerController.text,
              );
              
              // Save the updated question
              _interviewService.updateQuestion(updatedQuestion);
              
              // Close the dialog
              Navigator.pop(context);
              
              // Refresh the state to show updated question
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionSet = _interviewService.getQuestionSetById(widget.setId);
    
    if (questionSet == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Question Set'),
          backgroundColor: context.surfaceColor,
          foregroundColor: context.onSurfaceColor,
        ),
        body: const Center(child: Text('Question set not found')),
      );
    }
    
    final questions = _interviewService.getQuestionsForSet(widget.setId);
    
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: Text(questionSet.title),
        backgroundColor: context.surfaceColor,
        foregroundColor: context.onSurfaceColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: context.surfaceColor,
                  title: Text(
                    'Delete Question Set',
                    style: TextStyle(color: context.onSurfaceColor),
                  ),
                  content: Text(
                    'Are you sure you want to delete this question set? This cannot be undone.',
                    style: TextStyle(color: context.onSurfaceColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: context.primaryColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _interviewService.deleteQuestionSet(widget.setId);
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionSet.title,
                  style: context.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (questionSet.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      questionSet.description,
                      style: TextStyle(
                        color: context.onSurfaceColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Questions (${questions.length})',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // Practice all questions
                      },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Practice All'),
                      style: TextButton.styleFrom(
                        backgroundColor: context.primaryColor.withOpacityFix(0.1),
                        foregroundColor: context.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: questions.isEmpty
                ? Center(
                    child: Text(
                      'No questions found in this set.',
                      style: TextStyle(color: context.onSurfaceVariantColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: context.surfaceColor,
                        elevation: context.cardElevation,
                        shape: Border(
                          left: BorderSide(
                            color: context.primaryColor,
                            width: 4,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            // Show question details
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: context.surfaceColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) => _buildQuestionDetail(context, question),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        question.text,
                                        style: context.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _interviewService.toggleStar(question.id);
                                        });
                                      },
                                      icon: Icon(
                                        question.isStarred ? Icons.star : Icons.star_border,
                                        color: question.isStarred ? Colors.amber : context.onSurfaceVariantColor,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildCategoryTag(context, question.category),
                                    _buildSubtopicTag(context, question.subtopic),
                                    _buildDifficultyTag(context, question.difficulty),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        // Practice functionality
                                      },
                                      icon: const Icon(Icons.play_arrow, size: 16),
                                      label: const Text('Practice'),
                                      style: TextButton.styleFrom(
                                        backgroundColor: context.primaryColor.withOpacityFix(0.1),
                                        foregroundColor: context.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        // Show answer in a dialog
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: context.surfaceColor,
                                            title: Text(
                                              'Example Answer',
                                              style: TextStyle(color: context.onSurfaceColor),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Text(
                                                question.answer ?? 'No answer provided',
                                                style: TextStyle(color: context.onSurfaceColor),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(
                                                  'Close',
                                                  style: TextStyle(color: context.primaryColor),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: context.primaryColor,
                                      ),
                                      child: const Text('View Answer'),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () {
                                        // Share functionality
                                      },
                                      icon: Icon(
                                        Icons.share,
                                        size: 18,
                                        color: context.onSurfaceVariantColor,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        // Edit functionality using our new method
                                        _editQuestion(question);
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: context.onSurfaceVariantColor,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionDetail(BuildContext context, InterviewQuestion question) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.onSurfaceVariantColor.withOpacityFix(0.5),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                    margin: const EdgeInsets.only(bottom: 24),
                  ),
                ),
                Text(
                  'Question',
                  style: context.titleSmall?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.text,
                  style: context.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Answer',
                  style: context.titleSmall?.copyWith(
                    color: context.onSurfaceVariantColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.answer ?? 'No answer provided',
                  style: context.bodyLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: context.titleSmall?.copyWith(
                              color: context.onSurfaceVariantColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildCategoryTag(context, question.category),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Difficulty',
                            style: context.titleSmall?.copyWith(
                              color: context.onSurfaceVariantColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDifficultyTag(context, question.difficulty),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Practice functionality
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Practice'),
                      style: TextButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: context.onPrimaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Edit functionality using our new method
                        Navigator.pop(context);
                        _editQuestion(question);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        backgroundColor: context.surfaceColor,
                        foregroundColor: context.onSurfaceColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCategoryTag(BuildContext context, String category) {
    String label;
    Color backgroundColor;
    Color textColor;
    
    switch (category) {
      case 'technical':
        label = 'Technical Knowledge';
        backgroundColor = context.isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100;
        textColor = context.isDarkMode ? Colors.blue.shade100 : Colors.blue.shade900;
        break;
      case 'applied':
        label = 'Applied Skills';
        backgroundColor = context.isDarkMode ? Colors.green.shade900 : Colors.green.shade100;
        textColor = context.isDarkMode ? Colors.green.shade100 : Colors.green.shade900;
        break;
      case 'behavioral':
        label = 'Behavioral Questions';
        backgroundColor = context.isDarkMode ? Colors.yellow.shade900 : Colors.yellow.shade100;
        textColor = context.isDarkMode ? Colors.yellow.shade100 : Colors.yellow.shade900;
        break;
      case 'case':
        label = 'Case Study';
        backgroundColor = context.isDarkMode ? Colors.purple.shade900 : Colors.purple.shade100;
        textColor = context.isDarkMode ? Colors.purple.shade100 : Colors.purple.shade900;
        break;
      case 'job':
        label = 'Job-Specific';
        backgroundColor = context.isDarkMode ? Colors.orange.shade900 : Colors.orange.shade100;
        textColor = context.isDarkMode ? Colors.orange.shade100 : Colors.orange.shade900;
        break;
      default:
        label = 'Other';
        backgroundColor = context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
        textColor = context.isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
  
  Widget _buildSubtopicTag(BuildContext context, String subtopic) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        subtopic,
        style: TextStyle(
          fontSize: 12,
          color: context.isDarkMode ? Colors.grey.shade200 : Colors.grey.shade800,
        ),
      ),
    );
  }
  
  Widget _buildDifficultyTag(BuildContext context, String difficulty) {
    String label;
    Color backgroundColor;
    Color textColor;
    
    switch (difficulty) {
      case 'entry':
        label = 'Entry Level';
        backgroundColor = context.isDarkMode ? const Color(0xFF1B3B29) : Colors.green.shade50;
        textColor = context.isDarkMode ? const Color(0xFFB8E5CA) : Colors.green.shade900;
        break;
      case 'mid':
        label = 'Mid Level';
        backgroundColor = context.isDarkMode ? const Color(0xFF3B3A1F) : Colors.yellow.shade50;
        textColor = context.isDarkMode ? const Color(0xFFF0E68C) : Colors.amber.shade900;
        break;
      case 'senior':
        label = 'Senior Level';
        backgroundColor = context.isDarkMode ? const Color(0xFF3B2929) : Colors.red.shade50;
        textColor = context.isDarkMode ? const Color(0xFFFFCCCB) : Colors.red.shade900;
        break;
      default:
        label = 'Unknown';
        backgroundColor = context.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100;
        textColor = context.isDarkMode ? Colors.grey.shade100 : Colors.grey.shade800;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.isDarkMode 
            ? textColor.withOpacityFix(0.3) 
            : backgroundColor.withOpacityFix(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}