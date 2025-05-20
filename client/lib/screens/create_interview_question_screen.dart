import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interview_question.dart';
import '../services/interview_service.dart';
import '../utils/colors.dart';
import '../utils/category_mapper.dart';

class CreateInterviewQuestionScreen extends StatefulWidget {
  final InterviewQuestion? questionToEdit;

  const CreateInterviewQuestionScreen({super.key, this.questionToEdit});

  @override
  State<CreateInterviewQuestionScreen> createState() =>
      _CreateInterviewQuestionScreenState();
}

class _CreateInterviewQuestionScreenState
    extends State<CreateInterviewQuestionScreen> {
  // Current step in the creation process (1: Details, 2: Answer, 3: Review)
  int _currentStep = 1;

  // Form controllers
  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _answerTextController = TextEditingController();

  // Form data
  String _selectedCategory = '';
  String _selectedSubtopic = '';
  String _selectedDifficulty = '';
  String _customSubtopic = '';
  bool _isAddingCustomSubtopic = false;

  @override
  void initState() {
    super.initState();

    // If editing existing question, populate form fields
    if (widget.questionToEdit != null) {
      _questionTextController.text = widget.questionToEdit!.text;
      _answerTextController.text = widget.questionToEdit!.answer ?? '';
      _selectedCategory = widget.questionToEdit!.category;
      _selectedSubtopic = widget.questionToEdit!.subtopic;
      _selectedDifficulty = widget.questionToEdit!.difficulty;
    }
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _answerTextController.dispose();
    super.dispose();
  }

  // Define available categories with their subtopics
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'technical',
      'name': 'Technical Knowledge',
      'color': Colors.blue.shade100,
      'icon': Icons.article,
      'subtopics': [
        'Machine Learning Algorithms',
        'SQL & Database',
        'Data Structures',
        'Statistics',
        'Python Fundamentals',
      ],
    },
    {
      'id': 'applied',
      'name': 'Applied Skills',
      'color': Colors.green.shade100,
      'icon': Icons.build,
      'subtopics': [
        'Data Cleaning & Preprocessing',
        'Model Evaluation',
        'Feature Engineering',
        'Data Visualization',
      ],
    },
    {
      'id': 'case',
      'name': 'Case Studies',
      'color': Colors.purple.shade100,
      'icon': Icons.assessment,
      'subtopics': [
        'Model Building Scenarios',
        'Business Problem Solving',
        'System Design',
        'Product Analytics',
      ],
    },
    {
      'id': 'behavioral',
      'name': 'Behavioral Questions',
      'color': Colors.yellow.shade100,
      'icon': Icons.people,
      'subtopics': [
        'Communication Skills',
        'Teamwork',
        'Problem Solving',
        'Leadership',
      ],
    },
    {
      'id': 'job',
      'name': 'Job-Specific',
      'color': Colors.red.shade100,
      'icon': Icons.work,
      'subtopics': [
        'Data Scientist',
        'ML Engineer',
        'Data Analyst',
        'Data Engineer',
      ],
    },
  ];

  // Define difficulty levels
  final List<Map<String, dynamic>> _difficultyLevels = [
    {
      'id': 'entry',
      'name': 'Entry Level',
      'color': Colors.green.shade100,
      'textColor': Colors.green.shade800,
    },
    {
      'id': 'mid',
      'name': 'Mid Level',
      'color': Colors.yellow.shade100,
      'textColor': Colors.yellow.shade800,
    },
    {
      'id': 'senior',
      'name': 'Senior Level',
      'color': Colors.red.shade100,
      'textColor': Colors.red.shade800,
    },
  ];

  // Helper method to get available subtopics for selected category
  List<String> _getSubtopics() {
    if (_selectedCategory.isEmpty) return [];

    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => {'subtopics': <String>[]},
    );

    // Start with standard subtopics
    List<String> subtopics = List<String>.from(category['subtopics'] ?? []);
    
    // Include the current selected subtopic if it's not already in the list
    // This prevents the dropdown assertion error by ensuring the value always has a matching item
    if (_selectedSubtopic.isNotEmpty && 
        !subtopics.contains(_selectedSubtopic) && 
        _selectedSubtopic != 'Add new subtopic...') {
      subtopics.add(_selectedSubtopic);
    }
    
    // Add the "Add new subtopic..." option
    subtopics.add('Add new subtopic...');
    
    return subtopics;
  }

  // Navigate to next step
  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  // Navigate to previous step
  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // Save the question
  Future<void> _saveQuestion({bool asDraft = false}) async {
    // Get the interview service
    final interviewService = Provider.of<InterviewService>(
      context, 
      listen: false,
    );

    // Create new question or update existing one
    final question = InterviewQuestion(
      id: widget.questionToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      text: _questionTextController.text,
      category: _selectedCategory,  // This is already the internal category ID
      subtopic: _selectedSubtopic,
      difficulty: _selectedDifficulty,
      answer: _answerTextController.text,
      isDraft: asDraft,
    );

    try {
      // Show debug info
      debugPrint('Saving question: ${question.text}');
      debugPrint('Category: ${question.category} (Maps to ${CategoryMapper.getDefaultCategory(question.category)})');
      debugPrint('isDraft: $asDraft');
      
      if (widget.questionToEdit != null) {
        await interviewService.updateQuestion(question);
        debugPrint('Updated existing question');
      } else {
        await interviewService.addQuestion(question);
        debugPrint('Added new question');
      }

      // Display success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(asDraft ? 'Question saved as draft' : 'Question published successfully'),
            backgroundColor: asDraft ? Colors.blue : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Navigate back to the questions screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Display error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving question: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.questionToEdit != null ? 'Edit Question' : 'Create Question',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // FAB removed from all steps
      body: Column(
        children: [
          // Steps indicator
          _buildStepIndicator(),

          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Build step indicator UI
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          // Step 1
          _buildStepCircle(1, 'Question'),
          _buildStepConnector(_currentStep > 1),

          // Step 2
          _buildStepCircle(2, 'Answer'),
          _buildStepConnector(_currentStep > 2),

          // Step 3
          _buildStepCircle(3, 'Review'),
        ],
      ),
    );
  }

  // Build individual step circle
  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.textPrimary : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Build connector between steps
  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }

  // Build content for current step
  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Content();
      case 2:
        return _buildStep2Content();
      case 3:
        return _buildStep3Content();
      default:
        return Container();
    }
  }

  // Step 1: Question details form
  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text field
        Text(
          'Question Text',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _questionTextController,
          decoration: InputDecoration(
            hintText: 'Enter your interview question here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          maxLines: 4,
        ),

        const SizedBox(height: 24),

        // Category selection
        Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),

        const SizedBox(height: 8),

        // Grid of category options
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == category['id'];

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category['id'];
                  _selectedSubtopic =
                      ''; // Reset subtopic when category changes
                  _isAddingCustomSubtopic = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? category['color'] : Colors.transparent,
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      category['icon'],
                      size: 18,
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Subtopic selection (only show if category is selected)
        if (_selectedCategory.isNotEmpty) ...[
          Text(
            'Subtopic',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),

          const SizedBox(height: 8),

          if (!_isAddingCustomSubtopic)
            DropdownButtonFormField<String>(
              value: _selectedSubtopic.isNotEmpty ? _selectedSubtopic : null,
              decoration: InputDecoration(
                hintText: 'Select a subtopic',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              items:
                  _getSubtopics().map((subtopic) {
                    return DropdownMenuItem<String>(
                      value: subtopic,
                      child: Text(subtopic),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  if (value == 'Add new subtopic...') {
                    _isAddingCustomSubtopic = true;
                    _selectedSubtopic = '';
                  } else if (value != null) {
                    _selectedSubtopic = value;
                  }
                });
              },
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Enter new subtopic',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customSubtopic = value;
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _customSubtopic.isNotEmpty
                          ? () {
                            setState(() {
                              // Set the selected subtopic to the custom value
                              _selectedSubtopic = _customSubtopic;
                              
                              // Add to the category's subtopics list for persistence
                              for (var category in _categories) {
                                if (category['id'] == _selectedCategory) {
                                  if (!category['subtopics'].contains(_customSubtopic)) {
                                    category['subtopics'].add(_customSubtopic);
                                  }
                                  break;
                                }
                              }
                              
                              // Switch back to dropdown view
                              _isAddingCustomSubtopic = false;
                            });
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Add'),
                ),
              ],
            ),
        ],

        const SizedBox(height: 24),

        // Difficulty selection
        Text(
          'Difficulty Level',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),

        const SizedBox(height: 8),

        // Row of difficulty options
        Row(
          children:
              _difficultyLevels.map((difficulty) {
                final isSelected = _selectedDifficulty == difficulty['id'];

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDifficulty = difficulty['id'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? difficulty['color']
                                  : Colors.transparent,
                          border: Border.all(
                            color:
                                isSelected
                                    ? difficulty['textColor']
                                    : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            difficulty['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isSelected
                                      ? difficulty['textColor']
                                      : Colors.grey.shade700,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),

        const SizedBox(height: 32),

        // Next button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _canProceedToStep2() ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Next'),
          ),
        ),
      ],
    );
  }

  // Check if can proceed to step 2
  bool _canProceedToStep2() {
    return _questionTextController.text.isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        _selectedSubtopic.isNotEmpty &&
        _selectedDifficulty.isNotEmpty;
  }

  // Step 2: Answer form
  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  // Difficulty tag
                  _selectedDifficulty.isNotEmpty
                      ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getDifficultyName(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDifficultyTextColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      : SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 8),
              Text(_questionTextController.text),
              const SizedBox(height: 8),
              if (_selectedCategory.isNotEmpty && _selectedSubtopic.isNotEmpty)
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getCategoryName(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedSubtopic,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Answer field with guidance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Answer',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            // Template button
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _answerTextController.text = _getAnswerTemplate();
                });
              },
              icon: Icon(Icons.article, size: 16),
              label: Text('Use Template'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _answerTextController,
          decoration: InputDecoration(
            hintText: 'Provide a detailed answer for this interview question',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          maxLines: 10,
        ),

        const SizedBox(height: 16),

        // Answer guidelines
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Answer Guidelines:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue.shade800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ..._getGuidelinesForCategory().map((guideline) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          guideline,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Navigation buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text('Back'),
            ),
            ElevatedButton(
              onPressed:
                  _answerTextController.text.isNotEmpty ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  // Get template based on question category
  String _getAnswerTemplate() {
    switch (_selectedCategory) {
      case 'technical':
        return '## Key Concepts\n• \n• \n• \n\n## Examples\n• \n• \n\n## Code Sample\n```python\n# Add your code here\n```\n\n## Applications\n• \n• ';
      case 'applied':
        return '## Approach\n• \n• \n\n## Step-by-Step Method\n1. \n2. \n3. \n\n## Alternatives\n• \n• \n\n## Pros and Cons\n**Pros:**\n• \n• \n\n**Cons:**\n• \n• ';
      case 'case':
        return '## Problem Analysis\n• \n• \n\n## Solution Approach\n• \n• \n\n## Implementation\n• \n• \n\n## Evaluation\n• \n• ';
      case 'behavioral':
        return '## Situation\n\n## Task\n\n## Action\n\n## Result\n\n## Lessons Learned\n• \n• ';
      case 'job':
        return '## Role Requirements\n• \n• \n\n## Technical Skills\n• \n• \n\n## Industry Knowledge\n• \n• \n\n## Career Growth\n• \n• ';
      default:
        return '## Key Points\n• \n• \n• \n\n## Examples\n• \n• \n\n## Best Practices\n• \n• ';
    }
  }

  // Get guidelines based on question category
  List<String> _getGuidelinesForCategory() {
    final List<String> baseGuidelines = [
      'Start with a clear, concise explanation of key concepts',
      'Include practical examples where applicable',
      'End with best practices or a summary of the main points',
    ];

    switch (_selectedCategory) {
      case 'technical':
        return [
          ...baseGuidelines,
          'Include code snippets or formulas if relevant',
          'Explain why certain approaches are preferred over others',
          'Reference common libraries, tools, or frameworks if applicable',
        ];
      case 'applied':
        return [
          ...baseGuidelines,
          'Describe multiple approaches to solve the problem',
          'Discuss trade-offs between different methods',
          'Include performance considerations and limitations',
        ];
      case 'case':
        return [
          ...baseGuidelines,
          'Break down the problem into manageable components',
          'Discuss how to handle edge cases and limitations',
          'Include metrics to evaluate the solution\'s effectiveness',
        ];
      case 'behavioral':
        return [
          'Use the STAR method (Situation, Task, Action, Result)',
          'Focus on your specific contributions and actions',
          'Quantify results and impact where possible',
          'Share what you learned from the experience',
        ];
      case 'job':
        return [
          ...baseGuidelines,
          'Discuss industry-specific knowledge and standards',
          'Include relevant certifications or qualifications',
          'Mention both technical and soft skills required for the role',
        ];
      default:
        return baseGuidelines;
    }
  }

  // Step 3: Review screen
  Widget _buildStep3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Question',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 16),

        // Question card preview
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _questionTextController.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.star_border,
                            color: Colors.grey.shade400,
                          ),
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Category and difficulty tags
                    Row(
                      children: [
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getCategoryName(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Subtopic
                        Text(
                          '• $_selectedSubtopic',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const Spacer(),

                        // Difficulty tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getDifficultyName(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getDifficultyTextColor(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Practice',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'View Answer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Share and edit buttons
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {},
                        ),

                        const SizedBox(width: 16),

                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.grey.shade500,
                          ),
                          constraints: BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _currentStep = 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Answer preview
        Text(
          'Answer Preview',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),

        const SizedBox(height: 8),

        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: Text(
              _answerTextController.text,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Review checklist
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.yellow.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before submitting, please check:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.yellow.shade800,
                ),
              ),
              const SizedBox(height: 8),
              _buildChecklistItem('Question is clear and concise'),
              _buildChecklistItem('Category and subtopic are appropriate'),
              _buildChecklistItem('Difficulty level is accurately set'),
              _buildChecklistItem('Answer is comprehensive and accurate'),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Navigation and save buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: _previousStep,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text('Back'),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _saveQuestion(asDraft: true),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text('Save as Draft'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _saveQuestion(asDraft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Publish Question'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Build checklist item
  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.yellow.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.yellow.shade700),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for category and difficulty display
  Color _getCategoryColor() {
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => {'color': Colors.grey.shade100},
    );
    return category['color'];
  }

  String _getCategoryName() {
    final category = _categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => {'name': 'Unknown'},
    );
    return category['name'];
  }

  Color _getDifficultyColor() {
    final difficulty = _difficultyLevels.firstWhere(
      (d) => d['id'] == _selectedDifficulty,
      orElse: () => {'color': Colors.grey.shade100},
    );
    return difficulty['color'];
  }

  Color _getDifficultyTextColor() {
    final difficulty = _difficultyLevels.firstWhere(
      (d) => d['id'] == _selectedDifficulty,
      orElse: () => {'textColor': Colors.grey.shade800},
    );
    return difficulty['textColor'];
  }

  String _getDifficultyName() {
    final difficulty = _difficultyLevels.firstWhere(
      (d) => d['id'] == _selectedDifficulty,
      orElse: () => {'name': 'Unknown'},
    );
    return difficulty['name'];
  }
}
