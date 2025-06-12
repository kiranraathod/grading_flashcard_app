import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../widgets/interview/category_filter.dart';
import '../widgets/interview/difficulty_filter.dart';
import '../widgets/interview/interview_question_card_improved.dart';
import '../widgets/interview/answer_view.dart';
import '../widgets/multi_action_fab.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../utils/design_system.dart';
import '../utils/theme_utils.dart';
import '../utils/colors.dart';
import '../utils/category_mapper.dart';
import '../utils/dialogs/delete_confirmation_dialog.dart';
import 'create_interview_question_screen.dart';
import 'interview_practice_screen.dart';
import 'job_description_question_generator_screen.dart';
import 'create_flashcard_screen.dart';

class InterviewQuestionsScreen extends StatefulWidget {
  final String category;
  final bool isSubtopic; // New parameter to indicate if category is actually a subtopic
  
  const InterviewQuestionsScreen({
    super.key,
    required this.category,
    this.isSubtopic = false, // Default to false for backward compatibility
  });
  
  @override
  State<InterviewQuestionsScreen> createState() => _InterviewQuestionsScreenState();
}

class _InterviewQuestionsScreenState extends State<InterviewQuestionsScreen> {
  String _activeCategory = 'all';
  String _activeDifficulty = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  InterviewService? _interviewService;

  @override
  void initState() {
    super.initState();
    // Initialize active category from widget parameter if provided
    // ✅ FIX: Don't map category when it's a subtopic - use original name
    if (widget.isSubtopic) {
      _activeCategory = widget.category; // Use subtopic name directly
      debugPrint('🔧 SUBTOPIC MODE: Using "${widget.category}" as subtopic (no mapping)');
    } else {
      _activeCategory = _mapRecenTabCategoryToFilterId(widget.category);
      debugPrint('🔧 CATEGORY MAPPING: "${widget.category}" → "$_activeCategory"');
    }
    // InterviewService will be provided in didChangeDependencies
  }
  
  /// ✅ NEW: Map category from Recent tab to proper filter ID
  String _mapRecenTabCategoryToFilterId(String category) {
    // Handle direct matches (most common case)
    const filterIds = ['all', 'technical', 'applied', 'case', 'behavioral', 'job'];
    if (filterIds.contains(category)) {
      return category;
    }
    
    // Handle UI display names to filter IDs
    switch (category.toLowerCase()) {
      case 'technical knowledge':
        return 'technical';
      case 'applied skills':
        return 'applied';
      case 'case studies':
        return 'case';
      case 'behavioral questions':
        return 'behavioral';
      case 'job-specific':
        return 'job';
      // ✅ NEW: Handle subtopic-to-category mapping for recent items
      case 'api development':
      case 'web development':
        return 'job';
      case 'data analysis':
      case 'data cleaning & preprocessing':
        return 'technical';
      case 'machine learning':
      case 'ml algorithms':
        return 'applied';
      case 'sql & database':
      case 'sql':
        return 'technical';
      case 'python fundamentals':
      case 'python':
        return 'technical';
      case 'statistical analysis':
      case 'statistics':
        return 'case';
      default:
        debugPrint('⚠️ Unknown category "$category", defaulting to "all"');
        return 'all';
    }
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
  
  // Get filtered questions using the service - UPDATED: Support subtopic filtering
  List<InterviewQuestion> _getFilteredQuestions() {
    if (_interviewService == null) {
      return [];
    }
    
    final filteredQuestions = _interviewService!.getFilteredQuestions(
      category: _activeCategory,
      difficulty: _activeDifficulty,
      searchQuery: _searchController.text,
    );
    
    // ✅ SIMPLIFIED: Essential debugging for filtering issues (reduced for cleaner logs)
    if (_activeCategory != 'all' && kDebugMode) {
      final allQuestions = _interviewService!.questions;
      debugPrint('=== FILTER DEBUG: $_activeCategory ===');
      debugPrint('Total questions: ${allQuestions.length}');
      debugPrint('Filtered result: ${filteredQuestions.length}');
      
      if (filteredQuestions.isEmpty && allQuestions.isNotEmpty) {
        debugPrint('🚨 NO MATCHES - Sample question: ${allQuestions.first.categoryId} → ${CategoryMapper.mapInternalToUICategory(allQuestions.first.categoryId ?? '')}');
      }
    }
    
    return filteredQuestions;
  }

  // Handle delete question with confirmation
  Future<void> _handleDeleteQuestion(BuildContext context, InterviewQuestion question) async {
    // Get scaffold messenger reference before any async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      itemName: question.text.length > 50 
          ? '${question.text.substring(0, 50)}...' 
          : question.text,
      itemType: 'question',
    );

    if (confirmed) {
      try {
        _interviewService?.deleteQuestion(question.id);
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Question deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {}); // Refresh the UI
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to delete question'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  // Helper method to check special subtopic matches (same as service)
  // UNUSED: Kept for potential future use
  // bool _isSpecialSubtopicMatch(String uiCategory, InterviewQuestion question) {
  //   final subtopicLower = question.subtopic.toLowerCase();
  //   
  //   switch (uiCategory) {
  //     case 'SQL':
  //       return subtopicLower.contains('sql') || subtopicLower.contains('database');
  //     case 'Python':
  //       return subtopicLower.contains('python');
  //     case 'Data Analysis':
  //       return subtopicLower.contains('data') || subtopicLower.contains('analysis');
  //     case 'Machine Learning':
  //       return subtopicLower.contains('ml') || subtopicLower.contains('machine learning');
  //     case 'Web Development':
  //       return subtopicLower.contains('web') || subtopicLower.contains('api');
  //     case 'Statistics':
  //       return subtopicLower.contains('statistical') || subtopicLower.contains('statistics');
  //     default:
  //       return false;
  //   }
  // }
  
  // Calculate progress for the user using the service
  (int, int) _calculateProgress() {
    if (_interviewService == null) {
      return (0, 0);
    }
    
    final stats = _interviewService!.getProgressStats();
    final completedValue = stats['completed'];
    final totalValue = stats['total'];
    
    final completed = (completedValue is int) ? completedValue : 0;
    final total = (totalValue is int) ? totalValue : 0;
    
    return (completed, total);
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _getFilteredQuestions();
    final (completed, total) = _calculateProgress();
    final progressPercent = total > 0 ? (completed / total * 100).round() : 0;
    
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
                style: TextStyle(
                  color: context.onSurfaceColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search, 
                    color: context.isDarkMode 
                        ? Colors.white.withValues(alpha: 0.8)  // Increased opacity for better visibility
                        : context.onSurfaceVariantColor,
                  ),
                  hintText: 'Search questions...',
                  hintStyle: TextStyle(
                    color: context.isDarkMode 
                        ? Colors.white.withValues(alpha: 0.6)  // Increased opacity for better readability
                        : context.onSurfaceVariantColor,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: context.isDarkMode 
                      ? const Color(0xFF3A3A42)  // Improved contrast for dark mode
                      : Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: context.primaryColor.withValues(alpha: 0.5),
                      width: 1,
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
                
                // ✅ REMOVED: Question Categories section per user request
                
                const SizedBox(height: DS.spacingL),
                
                // Questions header with count and refresh button
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Questions count
                      Text(
                        "Questions (${filteredQuestions.length})",
                        style: TextStyle(
                          fontSize: DS.isExtraSmallScreen(context) ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: context.isDarkMode 
                              ? AppColors.textPrimaryDark 
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      
                      // Responsive spacing - increased since Practice All button removed
                      SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacingS : DS.spacingL),
                      
                      // Refresh button
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
                          size: DS.isExtraSmallScreen(context) ? 14 : 16,
                          color: Colors.blue.shade600,
                        ),
                        label: Text(
                          'Refresh',
                          style: TextStyle(
                            fontSize: DS.isExtraSmallScreen(context) ? 11 : 13,
                            color: Colors.blue.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      
                      SizedBox(width: DS.isExtraSmallScreen(context) ? DS.spacing2xs : DS.spacingM),
                      
                      // Add Question button  
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
                          size: DS.isExtraSmallScreen(context) ? 14 : 16,
                          color: Colors.blue.shade600,
                        ),
                        label: Text(
                          'Add Question',
                          style: TextStyle(
                            fontSize: DS.isExtraSmallScreen(context) ? 11 : 13,
                            color: Colors.blue.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: DS.spacingM),
                
                // Question cards with answer modal functionality
                ...filteredQuestions.map((question) {
                  return InterviewQuestionCardImproved(
                    question: question,
                    onPractice: () {
                      // Navigate to practice screen with ONLY the selected question
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterviewPracticeScreen(
                            question: question,
                            questionList: [question],  // Create a list with only this question
                            currentIndex: 0,  // Set index to 0 since it's the only question
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
                        backgroundColor: context.isDarkMode 
                            ? const Color(0xFF2A2A30) 
                            : Colors.white,
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
                    onDelete: () => _handleDeleteQuestion(context, question),
                  );
                }),
                
                const SizedBox(height: DS.spacingL),
                
                // Progress section
                Container(
                  padding: const EdgeInsets.all(DS.spacingM),
                  decoration: BoxDecoration(
                    color: context.isDarkMode 
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.2)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    border: Border.all(
                      color: context.isDarkMode 
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
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
                              ? Colors.white.withValues(alpha: 0.1)
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
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          
                          Text(
                            '${total - completed} remaining',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.isDarkMode 
                                  ? Colors.white.withValues(alpha: 0.7)
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