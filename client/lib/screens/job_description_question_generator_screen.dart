import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job_description_analysis.dart';
import '../models/interview_question.dart';
import '../models/question_set.dart';
import '../services/job_description_service.dart';
import '../services/interview_service.dart';
import '../utils/theme_utils.dart';
import '../utils/dialogs/delete_confirmation_dialog.dart';
import 'interview_practice_screen.dart';

class JobDescriptionQuestionGeneratorScreen extends StatefulWidget {
  const JobDescriptionQuestionGeneratorScreen({super.key});

  @override
  State<JobDescriptionQuestionGeneratorScreen> createState() => _JobDescriptionQuestionGeneratorScreenState();
}

class _JobDescriptionQuestionGeneratorScreenState extends State<JobDescriptionQuestionGeneratorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final JobDescriptionService _jobDescriptionService = JobDescriptionService();
  late InterviewService _interviewService;
  String _searchQuery = '';
  bool _isLoading = false;
  List<InterviewQuestion> _generatedQuestions = [];
  String _title = '';
  int _wordCount = 0;
  final int _maxWordCount = 300;
  
  // Category checkboxes state
  final Map<String, bool> _categories = {
    'technical': true,
    'applied': true,
    'behavioral': true,
    'case': true,
    'job': true,
  };
  
  // Single difficulty level selection
  String _selectedDifficulty = 'mid'; // Default to mid level

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);
  }
  
  @override
  void initState() {
    super.initState();
    _jobDescriptionController.addListener(_updateWordCount);
  }

  void _updateWordCount() {
    setState(() {
      // Split by whitespace and filter out empty strings
      final words = _jobDescriptionController.text
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();
      _wordCount = words.length;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jobDescriptionController.removeListener(_updateWordCount);
    _jobDescriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // Generate questions from job description
  Future<void> _handleGenerateQuestions() async {
    final jobDescription = _jobDescriptionController.text.trim();
    
    if (jobDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a job description'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check word count limit
    if (_wordCount > _maxWordCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job description exceeds $_maxWordCount word limit. Please shorten it.'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // First, analyze the job description
      final JobDescriptionAnalysis jobAnalysis = await _jobDescriptionService.analyzeJobDescription(jobDescription);
      
      if (!mounted) return;
      
      // Then, generate questions based on the analysis
      final selectedCategories = _categories.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      if (selectedCategories.isEmpty) {
        throw Exception('Please select at least one category');
      }
      
      final generatedQuestions = await _jobDescriptionService.generateQuestions(
        jobAnalysis: jobAnalysis,
        categories: selectedCategories,
        difficultyLevels: [_selectedDifficulty], // Use single selected difficulty
        countPerCategory: 1, // Generate just one question per category
      );
      
      if (!mounted) return;
      
      setState(() {
        _generatedQuestions = generatedQuestions;
        _isLoading = false;
      });

      // Hide the description input after generating questions
      _hideDescriptionInput();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _showingDescription = true; // Show input form again on error
      });
      
      String errorMessage = e.toString();
      
      // Show error banner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: errorMessage.contains('Network is not connected') 
              ? const Text('Network is not connected') 
              : errorMessage.contains('Failed to generate questions')
                  ? const Text('Error: Failed to generate questions. The server encountered an issue processing your request. Please try again with a different input or fewer categories.')
                  : Text('Error: ${errorMessage.split(':').last.trim()}'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  bool _showingDescription = true;

  void _showDescriptionInput() {
    setState(() {
      _showingDescription = true;
    });
  }

  void _hideDescriptionInput() {
    setState(() {
      _showingDescription = false;
    });
  }
  
  // Toggle star for a question
  void _toggleStar(String id) {
    setState(() {
      final index = _generatedQuestions.indexWhere((q) => q.id == id);
      if (index != -1) {
        final updated = _generatedQuestions[index].copyWith(
          isStarred: !_generatedQuestions[index].isStarred,
        );
        _generatedQuestions[index] = updated;
      }
    });
  }
  
  // Edit question
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
              setState(() {
                final index = _generatedQuestions.indexWhere((q) => q.id == question.id);
                if (index != -1) {
                  _generatedQuestions[index] = question.copyWith(
                    text: questionTextController.text,
                    category: category,
                    subtopic: subtopicController.text,
                    difficulty: difficulty,
                    answer: answerController.text,
                  );
                }
              });
              Navigator.pop(context);
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

  // Handle delete question with confirmation
  Future<void> _handleDeleteQuestion(InterviewQuestion question) async {
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
        // Remove from local generated questions list
        setState(() {
          _generatedQuestions.removeWhere((q) => q.id == question.id);
        });
        
        // If the question was already saved to the interview service, delete it from there too
        _interviewService.deleteQuestion(question.id);
        
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Question deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
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
  
  // Save all questions and navigate to categories page
  void _saveAllQuestions() {
    // Validate input
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for this question set'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _title = title;
    });
    
    try {
      // Generate a unique ID for the question set
      final setId = DateTime.now().millisecondsSinceEpoch.toString();
      final questionIds = <String>[];
      
      // Mark questions as published (not drafts) before saving
      for (final question in _generatedQuestions) {
        // Create a published version (not a draft)
        final publishedQuestion = question.copyWith(isDraft: false);
        _interviewService.addQuestion(publishedQuestion);
        questionIds.add(publishedQuestion.id);
      }
      
      // Create and save the question set
      final questionSet = QuestionSet(
        id: setId,
        title: _title,
        description: "", // Empty description
        jobDescription: _jobDescriptionController.text,
        questionIds: questionIds,
        createdAt: DateTime.now(),
      );
      
      _interviewService.saveQuestionSet(questionSet);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question set saved successfully!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to the categories page
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving questions: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.onSurfaceColor,
        title: Text(
          'Create Questions from Job Description',
          style: context.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Remove the MultiActionFab/Create button
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search questions...',
                    prefixIcon: Icon(Icons.search, color: context.onSurfaceVariantColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: context.colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: context.colorScheme.outline),
                    ),
                    filled: true,
                    fillColor: context.surfaceColor,
                    hintStyle: TextStyle(color: context.onSurfaceVariantColor),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  style: TextStyle(color: context.onSurfaceColor),
                  cursorColor: context.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // Title and question count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_title.isNotEmpty)
                      Text(
                        _title,
                        style: context.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: _title.isNotEmpty ? 16 : 0),
                    Row(
                      children: [
                        Text(
                          'Questions (${_generatedQuestions.length})',
                          style: context.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_generatedQuestions.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: _saveAllQuestions,
                            icon: const Icon(Icons.save),
                            label: const Text('Save All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: context.onPrimaryColor,
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _showDescriptionInput,
                          icon: Icon(
                            Icons.refresh,
                            color: context.onSurfaceVariantColor,
                          ),
                          tooltip: 'Generate New Questions',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Questions list
              Expanded(
                child: _generatedQuestions.isEmpty
                    ? Center(
                        child: _showingDescription
                            ? const SizedBox() // Don't show message when description input is visible
                            : Text(
                                'No questions generated yet. Enter a job description to get started.',
                                style: TextStyle(color: context.onSurfaceVariantColor),
                                textAlign: TextAlign.center,
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _generatedQuestions.length,
                        itemBuilder: (context, index) {
                          final question = _generatedQuestions[index];
                          // Filter by search query
                          if (_searchQuery.isNotEmpty && 
                              !question.text.toLowerCase().contains(_searchQuery.toLowerCase())) {
                            return const SizedBox.shrink();
                          }
                          return _buildQuestionCard(question);
                        },
                      ),
              ),
            ],
          ),
          
          // Job description input overlay
          if (_showingDescription)
            _buildDescriptionInputOverlay(),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacityFix(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: context.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Generating questions...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Use our custom JobDescriptionFAB widget
      // The FloatingActionButton has been replaced with an action in the AppBar
    );
  }
  
  Widget _buildDescriptionInputOverlay() {
    return Container(
      color: context.backgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          Text(
            'Title',
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: TextStyle(color: context.onSurfaceColor),
            decoration: InputDecoration(
              hintText: 'Enter a title for this question set...',
              hintStyle: TextStyle(color: context.onSurfaceVariantColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: context.outlineColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: context.outlineColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: context.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: context.surfaceColor,
            ),
            cursorColor: context.primaryColor,
          ),
          const SizedBox(height: 16),
          
          // Job Description Field
          Text(
            'Job Description',
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Word count indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Word count: $_wordCount / $_maxWordCount',
                style: TextStyle(
                  color: _wordCount > _maxWordCount 
                      ? Colors.red 
                      : context.onSurfaceVariantColor,
                  fontSize: 12,
                ),
              ),
              if (_wordCount > _maxWordCount)
                Text(
                  'Exceeds limit',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _jobDescriptionController,
              maxLines: null,
              expands: true,
              style: TextStyle(color: context.onSurfaceColor),
              decoration: InputDecoration(
                hintText: 'Paste job description here...',
                hintStyle: TextStyle(color: context.onSurfaceVariantColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: _wordCount > _maxWordCount 
                        ? Colors.red 
                        : context.outlineColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: _wordCount > _maxWordCount 
                        ? Colors.red 
                        : context.outlineColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: _wordCount > _maxWordCount 
                        ? Colors.red 
                        : context.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: context.surfaceColor,
              ),
              cursorColor: context.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Categories',
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Wrap(
            spacing: 8.0,
            children: [
              _buildCategoryCheckbox('technical', 'Technical'),
              _buildCategoryCheckbox('applied', 'Applied'),
              _buildCategoryCheckbox('behavioral', 'Behavioral'),
              _buildCategoryCheckbox('case', 'Case Study'),
              _buildCategoryCheckbox('job', 'Job-Specific'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Difficulty Level',
            style: context.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Wrap(
            spacing: 8.0,
            children: [
              _buildDifficultyRadio('entry', 'Entry'),
              _buildDifficultyRadio('mid', 'Mid'),
              _buildDifficultyRadio('senior', 'Senior'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_generatedQuestions.isNotEmpty)
                OutlinedButton(
                  onPressed: _hideDescriptionInput,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.onSurfaceColor,
                    side: BorderSide(color: context.outlineColor),
                  ),
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleGenerateQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: context.onPrimaryColor,
                ),
                child: const Text('Generate Questions'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCheckbox(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _categories[key] ?? false,
          activeColor: context.primaryColor,
          checkColor: context.onPrimaryColor,
          side: BorderSide(color: context.outlineColor),
          onChanged: (value) {
            setState(() {
              _categories[key] = value ?? false;
            });
          },
        ),
        Text(
          label,
          style: TextStyle(color: context.onSurfaceColor),
        ),
      ],
    );
  }
  
  Widget _buildDifficultyRadio(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: key,
          groupValue: _selectedDifficulty,
          activeColor: context.primaryColor,
          fillColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.selected)) {
              return context.primaryColor;
            }
            return context.outlineColor;
          }),
          onChanged: (value) {
            setState(() {
              _selectedDifficulty = value ?? 'mid';
            });
          },
        ),
        Text(
          label,
          style: TextStyle(color: context.onSurfaceColor),
        ),
      ],
    );
  }
  
  Widget _buildQuestionCard(InterviewQuestion question) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: context.cardElevation,
      color: context.surfaceColor,
      shape: Border(
        left: BorderSide(
          color: context.primaryColor,
          width: 4,
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
                Expanded(
                  child: Text(
                    question.text,
                    style: context.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleStar(question.id),
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
                _buildCategoryTag(question.category),
                _buildSubtopicTag(question.subtopic),
                _buildDifficultyTag(question.difficulty),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Practice this question
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterviewPracticeScreen(
                          question: question,
                          questionList: _generatedQuestions,
                          currentIndex: _generatedQuestions.indexOf(question),
                        ),
                      ),
                    ).then((_) {
                      // Refresh the state when returning from practice
                      setState(() {});
                    });
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _handleDeleteQuestion(question);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryTag(String category) {
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
  
  Widget _buildSubtopicTag(String subtopic) {
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
  
  Widget _buildDifficultyTag(String difficulty) {
    String label;
    Color backgroundColor;
    Color textColor;
    
    switch (difficulty) {
      case 'entry':
        label = 'Entry Level';
        backgroundColor = context.isDarkMode ? Color(0xFF1B3B29) : Colors.green.shade50;
        textColor = context.isDarkMode ? Color(0xFFB8E5CA) : Colors.green.shade900;
        break;
      case 'mid':
        label = 'Mid Level';
        backgroundColor = context.isDarkMode ? Color(0xFF3B3A1F) : Colors.yellow.shade50;
        textColor = context.isDarkMode ? Color(0xFFF0E68C) : Colors.amber.shade900;
        break;
      case 'senior':
        label = 'Senior Level';
        backgroundColor = context.isDarkMode ? Color(0xFF3B2929) : Colors.red.shade50;
        textColor = context.isDarkMode ? Color(0xFFFFCCCB) : Colors.red.shade900;
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