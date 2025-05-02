import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job_description_analysis.dart';
import '../models/interview_question.dart';
import '../services/job_description_service.dart';
import '../services/interview_service.dart';
import '../widgets/multi_action_fab.dart';
import 'create_flashcard_screen.dart';
import 'create_interview_question_screen.dart';

class JobDescriptionQuestionGeneratorScreen extends StatefulWidget {
  const JobDescriptionQuestionGeneratorScreen({super.key});

  @override
  State<JobDescriptionQuestionGeneratorScreen> createState() => _JobDescriptionQuestionGeneratorScreenState();
}

class _JobDescriptionQuestionGeneratorScreenState extends State<JobDescriptionQuestionGeneratorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final JobDescriptionService _jobDescriptionService = JobDescriptionService();
  late InterviewService _interviewService;
  String _searchQuery = '';
  bool _isLoading = false;
  List<InterviewQuestion> _generatedQuestions = [];
  
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
  void dispose() {
    _searchController.dispose();
    _jobDescriptionController.dispose();
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
        title: const Text('Edit Question'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Question Text', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: questionTextController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter question text',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: const [
                  DropdownMenuItem(value: 'technical', child: Text('Technical Knowledge')),
                  DropdownMenuItem(value: 'applied', child: Text('Applied Skills')),
                  DropdownMenuItem(value: 'behavioral', child: Text('Behavioral Questions')),
                  DropdownMenuItem(value: 'case', child: Text('Case Study')),
                  DropdownMenuItem(value: 'job', child: Text('Job-Specific')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    category = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Subtopic', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: subtopicController,
                decoration: InputDecoration(
                  hintText: 'Enter subtopic',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: difficulty,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                items: const [
                  DropdownMenuItem(value: 'entry', child: Text('Entry Level')),
                  DropdownMenuItem(value: 'mid', child: Text('Mid Level')),
                  DropdownMenuItem(value: 'senior', child: Text('Senior Level')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    difficulty = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              
              const Text('Example Answer', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: answerController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter example answer',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Save all questions and navigate to categories page
  void _saveAllQuestions() {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Mark questions as published (not drafts) before saving
      for (final question in _generatedQuestions) {
        // Create a published version (not a draft)
        final publishedQuestion = question.copyWith(isDraft: false);
        _interviewService.addQuestion(publishedQuestion);
      }
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All questions saved successfully!'),
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
      appBar: AppBar(
        title: const Text(
          'Create Questions from Job Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            label: 'Add Job Description',
            icon: Icons.description,
            onTap: _showDescriptionInput,
          ),
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
                if (mounted) setState(() {});
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
                if (mounted) setState(() {});
              });
            },
          ),
        ],
      ),
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
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // Questions count and action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Questions (${_generatedQuestions.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (_generatedQuestions.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _saveAllQuestions,
                        icon: const Icon(Icons.save),
                        label: const Text('Save All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showDescriptionInput,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Generate New Questions',
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
                            : const Text('No questions generated yet. Enter a job description to get started.'),
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
              color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 128),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
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
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Job Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _jobDescriptionController,
              maxLines: null,
              expands: true,
              decoration: InputDecoration(
                hintText: 'Paste job description here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
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
          const Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 16,
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
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _handleGenerateQuestions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
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
          onChanged: (value) {
            setState(() {
              _categories[key] = value ?? false;
            });
          },
        ),
        Text(label),
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
          onChanged: (value) {
            setState(() {
              _selectedDifficulty = value ?? 'mid';
            });
          },
        ),
        Text(label),
      ],
    );
  }
  
  Widget _buildQuestionCard(InterviewQuestion question) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: const Border(
        left: BorderSide(
          color: Colors.green,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleStar(question.id),
                  icon: Icon(
                    question.isStarred ? Icons.star : Icons.star_border,
                    color: question.isStarred ? Colors.amber : Colors.grey,
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
                    // Practice functionality would be implemented in a real app
                  },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Practice'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green.withValues(red: 0, green: 128, blue: 0, alpha: 26),
                    foregroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // Show answer in a dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Example Answer'),
                        content: SingleChildScrollView(
                          child: Text(question.answer ?? 'No answer provided'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('View Answer'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Share functionality
                  },
                  icon: const Icon(Icons.share, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _editQuestion(question);
                  },
                  icon: const Icon(Icons.edit, size: 18),
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
    
    switch (category) {
      case 'technical':
        label = 'Technical Knowledge';
        backgroundColor = Colors.blue.shade100;
        break;
      case 'applied':
        label = 'Applied Skills';
        backgroundColor = Colors.green.shade100;
        break;
      case 'behavioral':
        label = 'Behavioral Questions';
        backgroundColor = Colors.yellow.shade100;
        break;
      case 'case':
        label = 'Case Study';
        backgroundColor = Colors.purple.shade100;
        break;
      case 'job':
        label = 'Job-Specific';
        backgroundColor = Colors.orange.shade100;
        break;
      default:
        label = 'Other';
        backgroundColor = Colors.grey.shade100;
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
          color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
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
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        subtopic,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
  
  Widget _buildDifficultyTag(String difficulty) {
    String label;
    Color backgroundColor;
    
    switch (difficulty) {
      case 'entry':
        label = 'Entry Level';
        backgroundColor = Colors.green.shade50;
        break;
      case 'mid':
        label = 'Mid Level';
        backgroundColor = Colors.yellow.shade50;
        break;
      case 'senior':
        label = 'Senior Level';
        backgroundColor = Colors.red.shade50;
        break;
      default:
        label = 'Unknown';
        backgroundColor = Colors.grey.shade50;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor.withValues(
            red: backgroundColor.r.toDouble(), 
            green: backgroundColor.g.toDouble(), 
            blue: backgroundColor.b.toDouble(), 
            alpha: 128
          )),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}