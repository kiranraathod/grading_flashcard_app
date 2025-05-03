import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/interview/category_filter.dart';
import '../widgets/interview/difficulty_filter.dart';
import '../widgets/interview/interview_question_card.dart';
import '../widgets/interview/category_accordion.dart';
import '../widgets/interview/answer_view.dart';
import '../widgets/multi_action_fab.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';
import '../utils/colors.dart';
import 'create_interview_question_screen.dart';
import 'interview_practice_screen.dart';
import 'interview_practice_batch_screen.dart';
import 'job_description_question_generator_screen.dart';
import 'create_flashcard_screen.dart';

class InterviewQuestionsScreen extends StatefulWidget {
  final String category;
  
  const InterviewQuestionsScreen({
    super.key,
    required this.category,
  });
  
  @override
  State<InterviewQuestionsScreen> createState() => _InterviewQuestionsScreenState();
}

class _InterviewQuestionsScreenState extends State<InterviewQuestionsScreen> {
  String _activeCategory = 'all';
  String _activeDifficulty = 'all';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedCategories = {
    'technical': true,
    'applied': false,
    'case': false,
    'behavioral': false,
    'job': false,
  };
  
  InterviewService? _interviewService;

  @override
  void initState() {
    super.initState();
    // InterviewService will be provided in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Get filtered questions using the service
  List<InterviewQuestion> _getFilteredQuestions() {
    if (_interviewService == null) {
      return [];
    }
    
    return _interviewService!.getFilteredQuestions(
      category: _activeCategory,
      difficulty: _activeDifficulty,
      searchQuery: _searchController.text,
    );
  }
  
  // Toggle category expansion in the accordion
  void _toggleCategoryExpansion(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? false);
    });
  }
  
  // Get all subtopics for a category using the service
  List<String> _getCategorySubtopics(String category) {
    if (_interviewService == null) {
      return [];
    }
    
    return _interviewService!.getSubtopicsForCategory(category);
  }
  
  // Helper method to get category name
  String _getCategoryName(String categoryId) {
    switch (categoryId) {
      case 'technical':
        return 'Technical Knowledge';
      case 'applied':
        return 'Applied Skills';
      case 'case':
        return 'Case Studies';
      case 'behavioral':
        return 'Behavioral Questions';
      case 'job':
        return 'Job-Specific';
      default:
        return 'Other';
    }
  }
  
  // Helper method to get category icon
  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'technical':
        return Icons.bar_chart;
      case 'applied':
        return Icons.build;
      case 'case':
        return Icons.trending_up;
      case 'behavioral':
        return Icons.psychology;
      case 'job':
        return Icons.work;
      default:
        return Icons.help_outline;
    }
  }
  
  // Helper method to get category color
  Color _getCategoryColor(String categoryId) {
    final isDarkMode = context.isDarkMode;
    switch (categoryId) {
      case 'technical':
        return isDarkMode ? const Color(0xFF1E3A8A) : Colors.blue.shade100;
      case 'applied':
        return isDarkMode ? const Color(0xFF064E3B) : Colors.green.shade100;
      case 'case':
        return isDarkMode ? const Color(0xFF4C1D95) : Colors.purple.shade100;
      case 'behavioral':
        return isDarkMode ? const Color(0xFF854D0E) : Colors.yellow.shade100;
      case 'job':
        return isDarkMode ? const Color(0xFF991B1B) : Colors.red.shade100;
      default:
        return isDarkMode ? const Color(0xFF374151) : Colors.grey.shade100;
    }
  }
  
  // Calculate progress for the user using the service
  (int, int) _calculateProgress() {
    if (_interviewService == null) {
      return (0, 0);
    }
    
    final stats = _interviewService!.getProgressStats();
    return (stats['completed'] as int, stats['total'] as int);
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _getFilteredQuestions();
    final (completed, total) = _calculateProgress();
    final progressPercent = total > 0 ? (completed / total * 100).round() : 0;
    
    // Get categories from questions for the accordion
    final categories = ['technical', 'applied', 'case', 'behavioral', 'job'];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.category} Interview Questions',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: MultiActionFab(
        backgroundColor: Colors.green,
        tooltip: 'Create new content',
        options: [
          MultiActionFabOption(
            label: 'Create New Question',
            icon: Icons.add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateInterviewQuestionScreen(),
                ),
              ).then((_) {
                setState(() {}); // Refresh list
              });
            },
          ),
          MultiActionFabOption(
            label: 'Generate from Job Description',
            icon: Icons.description,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JobDescriptionQuestionGeneratorScreen(),
                ),
              ).then((_) {
                setState(() {}); // Refresh list
              });
            },
          ),
          MultiActionFabOption(
            label: 'Create Flashcards',
            icon: Icons.style,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateFlashcardScreen(),
                ),
              ).then((_) {
                setState(() {}); // Refresh list
              });
            },
          ),
        ],
      ),
      body: Container(
        color: context.backgroundColor,
        child: Column(
          children: [
            // Search bar
            Container(
              color: context.backgroundColor,
              padding: const EdgeInsets.fromLTRB(
                DS.spacingL,
                0,
                DS.spacingL,
                DS.spacingM,
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: context.onSurfaceColor),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search, 
                    color: context.isDarkMode 
                        ? Colors.white.withOpacity(0.7)
                        : context.onSurfaceVariantColor,
                  ),
                  hintText: 'Search questions...',
                  hintStyle: TextStyle(
                    color: context.isDarkMode 
                        ? Colors.white.withOpacity(0.5)
                        : context.onSurfaceVariantColor,
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? const Color(0xFF2C2C2E)
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: context.isDarkMode 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: context.isDarkMode 
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: context.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          
          // Main content with filters and questions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DS.spacingL),
              children: [
                // Category filter
                CategoryFilter(
                  activeCategory: _activeCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _activeCategory = category;
                    });
                  },
                ),
                
                const SizedBox(height: DS.spacingL),
                
                // Difficulty filter
                DifficultyFilter(
                  activeDifficulty: _activeDifficulty,
                  onDifficultySelected: (difficulty) {
                    setState(() {
                      _activeDifficulty = difficulty;
                    });
                  },
                ),
                
                const SizedBox(height: DS.spacingL),
                
                // Question Categories Header
                Text(
                  'Question Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
                
                const SizedBox(height: DS.spacingS),
                
                // Using our category accordion widget
                ...categories.map((category) {
                  final subtopics = _getCategorySubtopics(category);
                  final isExpanded = _expandedCategories[category] ?? false;
                  
                  return CategoryAccordion(
                    categoryId: category,
                    categoryName: _getCategoryName(category),
                    categoryIcon: _getCategoryIcon(category),
                    categoryColor: _getCategoryColor(category),
                    subtopics: subtopics,
                    isExpanded: isExpanded,
                    onToggle: () => _toggleCategoryExpansion(category),
                  );
                }),
                
                const SizedBox(height: DS.spacingL),
                
                // Questions header with count and practice all button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions (${filteredQuestions.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    
                    // Practice all, refresh and add buttons
                    Row(
                      children: [
                        // Practice all button
                        ElevatedButton.icon(
                          onPressed: filteredQuestions.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InterviewPracticeBatchScreen(
                                        questions: filteredQuestions,
                                        categoryName: widget.category,
                                      ),
                                    ),
                                  ).then((_) {
                                    // Refresh the questions list when returning
                                    setState(() {});
                                  });
                                }
                              : null,
                          icon: const Icon(
                            Icons.play_circle,
                            size: 16,
                          ),
                          label: const Text('Practice All'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: DS.spacingS),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              // Reload questions
                              // Just trigger a refresh - _questions field was removed
                              // Service will reload questions as needed
                            });
                          },
                          icon: Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          label: Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        
                        const SizedBox(width: DS.spacingM),
                        
                        TextButton.icon(
                          onPressed: () {
                            // Navigate to create interview question screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateInterviewQuestionScreen(),
                              ),
                            ).then((_) {
                              // Refresh the questions list when returning
                              setState(() {});
                            });
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          label: Text(
                            'Add Question',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: DS.spacingM),
                
                // Question cards with answer modal functionality
                ...filteredQuestions.map((question) {
                  return InterviewQuestionCard(
                    question: question,
                    onPractice: () {
                      // Navigate to practice screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterviewPracticeScreen(
                            question: question,
                            questionList: filteredQuestions,
                            currentIndex: filteredQuestions.indexOf(question),
                          ),
                        ),
                      ).then((_) {
                        // Refresh the questions list when returning
                        setState(() {});
                      });
                    },
                    onViewAnswer: () {
                      // Show answer modal
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(DS.borderRadiusSmall),
                          ),
                        ),
                        builder: (context) {
                          return AnswerView(
                            question: question,
                            onMarkComplete: () {
                              // Toggle completion status
                              _interviewService?.toggleCompletion(question.id);
                              Navigator.pop(context); // Close the modal
                            },
                            onClose: () {
                              Navigator.pop(context); // Close the modal
                            },
                          );
                        },
                      );
                    },
                    onToggleStar: () {
                      // Use the service to toggle star
                      _interviewService?.toggleStar(question.id);
                      setState(() {});
                    },
                    onShare: () {
                      // Share question - would implement sharing in a real app
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Sharing functionality would be implemented here'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onEdit: () {
                      // Navigate to edit screen with the current question
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateInterviewQuestionScreen(
                            questionToEdit: question,
                          ),
                        ),
                      ).then((_) {
                        // Refresh the questions list when returning
                        setState(() {});
                      });
                    },
                  );
                }),
                
                const SizedBox(height: DS.spacingL),
                
                // Progress section
                Container(
                  padding: const EdgeInsets.all(DS.spacingM),
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? const Color(0xFF1E3A8A).withOpacity(0.2)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    border: Border.all(
                      color: context.isDarkMode 
                          ? const Color(0xFF1E3A8A).withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Study Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      
                      const SizedBox(height: DS.spacingS),
                      
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent / 100,
                          backgroundColor: context.isDarkMode 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.isDarkMode 
                                ? const Color(0xFF93C5FD)
                                : Colors.blue.shade500,
                          ),
                          minHeight: 8,
                        ),
                      ),
                      
                      const SizedBox(height: DS.spacingS),
                      
                      // Progress stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$completed completed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: context.isDarkMode 
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          
                          Text(
                            '${total - completed} remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.isDarkMode 
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}