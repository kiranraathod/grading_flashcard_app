# Job Description Question Generator - Implementation Guide

This document provides all the code needed to implement the job description question generator feature.

## Backend Implementation

### 1. Job Description Service

File: `server/src/services/job_description_service.py`

```python
"""
Service for analyzing job descriptions and generating interview questions.
"""
import logging
import json
from typing import Dict, Any, List

from src.services.llm_service import LLMService

# Configure logging
logger = logging.getLogger(__name__)

class JobDescriptionService:
    """Service for analyzing job descriptions and generating interview questions."""
    
    def __init__(self, llm_service: LLMService):
        """Initialize the service."""
        self.llm_service = llm_service
        logger.debug("Initializing JobDescriptionService")
    
    async def analyze_job_description(self, job_description_text: str) -> Dict[str, Any]:
        """
        Analyze a job description to extract key information.
        
        Args:
            job_description_text: The full text of the job description
            
        Returns:
            Dictionary containing extracted skills, requirements and categories
        """
        logger.info("Analyzing job description")
        
        # Create prompt for the LLM
        prompt = self._create_analysis_prompt(job_description_text)
        
        # Use the LLM service's generate_content method
        response = await self.llm_service.client.generate_content_async(
            prompt, 
            temperature=0.2,  # Lower temperature for more focused analysis
            max_output_tokens=2048
        )
        
        # Parse the response
        try:
            analysis_result = json.loads(response.text)
            logger.debug(f"Successfully parsed job analysis: {analysis_result}")
            return analysis_result
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse job analysis response: {e}")
            logger.debug(f"Raw response: {response.text}")
            # Return a simplified result if parsing fails
            return {
                "required_skills": [],
                "desired_skills": [],
                "experience_level": "mid",
                "domain_knowledge": [],
                "soft_skills": [],
                "technologies": []
            }
    
    async def generate_questions(
        self, 
        job_analysis: Dict[str, Any],
        categories: List[str],
        difficulty_levels: List[str],
        count_per_category: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Generate interview questions based on job analysis.
        
        Args:
            job_analysis: The analysis result from analyze_job_description
            categories: Question categories to include (technical, applied, behavioral, case)
            difficulty_levels: Difficulty levels to include (entry, mid, senior)
            count_per_category: Number of questions per category
            
        Returns:
            List of generated questions with metadata
        """
        logger.info(f"Generating questions for categories: {categories}")
        
        all_questions = []
        
        for category in categories:
            # Create category-specific prompt
            prompt = self._create_question_generation_prompt(
                job_analysis, 
                category,
                difficulty_levels,
                count_per_category
            )
            
            # Use the LLM service to generate questions
            response = await self.llm_service.client.generate_content_async(
                prompt,
                temperature=0.7,  # Higher temperature for creative questions
                max_output_tokens=4096
            )
            
            # Parse the questions
            try:
                questions = json.loads(response.text)
                logger.debug(f"Generated {len(questions)} questions for category {category}")
                all_questions.extend(questions)
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse questions for category {category}: {e}")
                logger.debug(f"Raw response: {response.text}")
                # Add fallback questions if parsing fails
                all_questions.extend(self._generate_fallback_questions(category, count_per_category))
        
        return all_questions
    
    def _create_analysis_prompt(self, job_description: str) -> str:
        """Create a prompt for analyzing a job description."""
        return f"""
        You are an expert job analyst with deep experience in technical hiring.
        
        Analyze this job description and extract the following information in JSON format:
        
        JOB DESCRIPTION:
        {job_description}
        
        Extract and return ONLY a JSON object with the following structure:
        {{
            "required_skills": ["skill1", "skill2", ...],
            "desired_skills": ["skill1", "skill2", ...],
            "experience_level": "entry|mid|senior",
            "domain_knowledge": ["domain1", "domain2", ...],
            "soft_skills": ["skill1", "skill2", ...],
            "technologies": ["tech1", "tech2", ...]
        }}
        
        Be specific and granular with the skills and technologies. Extract actual names of programming languages, frameworks, methodologies, etc.
        
        Do not include any explanations, just return the valid JSON object.
        """
    
    def _create_question_generation_prompt(
        self, 
        job_analysis: Dict[str, Any],
        category: str,
        difficulty_levels: List[str],
        count: int
    ) -> str:
        """Create a prompt for generating interview questions."""
        # Extract relevant skills based on category
        relevant_skills = []
        if category == "technical":
            relevant_skills = job_analysis.get("required_skills", []) + job_analysis.get("technologies", [])
        elif category == "applied":
            relevant_skills = job_analysis.get("required_skills", []) + job_analysis.get("domain_knowledge", [])
        elif category == "behavioral":
            relevant_skills = job_analysis.get("soft_skills", [])
        elif category == "case":
            relevant_skills = job_analysis.get("domain_knowledge", [])
            
        # Format the difficulty levels for the prompt
        difficulty_str = ", ".join(difficulty_levels)
        
        # Create the prompt
        return f"""
        You are an expert technical interviewer with deep knowledge in hiring for technical roles.
        
        Generate {count} unique interview questions in the "{category}" category with varying difficulty levels ({difficulty_str}).
        
        The questions should be relevant to these skills and technologies:
        {", ".join(relevant_skills) if relevant_skills else "general skills for the job role"}
        
        For each question:
        1. Make it specific and challenging
        2. Ensure it evaluates real-world knowledge and not just theoretical concepts
        3. Create questions that can't be answered with a simple Google search
        4. Include a detailed example answer that demonstrates mastery
        
        Return your response as a JSON array with this structure:
        [
            {{
                "text": "question text",
                "category": "{category}",
                "subtopic": "specific skill or technology",
                "difficulty": "one of: {difficulty_str}",
                "answer": "detailed example answer"
            }},
            ...
        ]
        
        Vary the difficulty levels across the requested range ({difficulty_str}).
        Do not include any explanations, just return the valid JSON array.
        """
    
    def _generate_fallback_questions(self, category: str, count: int = 3) -> List[Dict[str, Any]]:
        """Generate fallback questions if LLM parsing fails."""
        questions = []
        
        # Basic templates for each category
        if category == "technical":
            templates = [
                "Explain the concept of [topic] and its applications.",
                "What are the key differences between [technology1] and [technology2]?",
                "How would you implement [technical solution] in practice?"
            ]
            subtopics = ["Programming Fundamentals", "Technical Concepts", "System Design"]
        elif category == "applied":
            templates = [
                "How would you approach solving [problem]?",
                "Describe your methodology for [task].",
                "What metrics would you use to evaluate [outcome]?"
            ]
            subtopics = ["Problem Solving", "Methodology", "Metrics & Evaluation"]
        elif category == "behavioral":
            templates = [
                "Describe a situation where you had to [challenge].",
                "Tell me about a time when you [situation].",
                "How do you handle [difficult situation]?"
            ]
            subtopics = ["Teamwork", "Communication", "Problem Resolution"]
        elif category == "case":
            templates = [
                "How would you design a system for [purpose]?",
                "A client is facing [problem]. How would you help them?",
                "Analyze this scenario: [business scenario]"
            ]
            subtopics = ["System Design", "Client Solutions", "Business Analysis"]
        else:
            templates = [
                "Explain your approach to [general topic].",
                "What are your thoughts on [industry trend]?",
                "How do you stay current with [field] developments?"
            ]
            subtopics = ["General Knowledge", "Industry Trends", "Professional Development"]
        
        # Generate the fallback questions
        difficulties = ["entry", "mid", "senior"]
        for i in range(min(count, len(templates))):
            questions.append({
                "text": f"FALLBACK QUESTION: {templates[i].replace('[topic]', 'this concept').replace('[technology1]', 'these technologies').replace('[technology2]', 'those technologies').replace('[technical solution]', 'this solution').replace('[problem]', 'this problem').replace('[task]', 'this task').replace('[outcome]', 'this outcome').replace('[challenge]', 'overcome this challenge').replace('[situation]', 'faced this situation').replace('[difficult situation]', 'this difficult situation').replace('[purpose]', 'this purpose').replace('[business scenario]', 'this scenario').replace('[general topic]', 'this topic').replace('[industry trend]', 'this trend').replace('[field]', 'your field')}",
                "category": category,
                "subtopic": subtopics[i % len(subtopics)],
                "difficulty": difficulties[i % len(difficulties)],
                "answer": "This is a fallback answer. The system was unable to generate a proper response. Please try again or create your own answer."
            })
        
        return questions
```

### 2. API Routes

File: `server/src/routes/job_description_routes.py`

```python
"""
API routes for job description analysis and question generation.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

from src.services.job_description_service import JobDescriptionService
from src.dependencies import get_job_description_service

router = APIRouter()

class JobDescriptionAnalysisRequest(BaseModel):
    job_description: str

class QuestionGenerationRequest(BaseModel):
    job_analysis: Dict[str, Any]
    categories: List[str]
    difficulty_levels: List[str]
    count_per_category: Optional[int] = 3

@router.post("/api/job-description/analyze")
async def analyze_job_description(
    request: JobDescriptionAnalysisRequest,
    job_description_service: JobDescriptionService = Depends(get_job_description_service)
):
    """Analyze a job description and extract key information."""
    result = await job_description_service.analyze_job_description(request.job_description)
    return result

@router.post("/api/job-description/generate-questions")
async def generate_job_questions(
    request: QuestionGenerationRequest,
    job_description_service: JobDescriptionService = Depends(get_job_description_service)
):
    """Generate interview questions based on job description analysis."""
    questions = await job_description_service.generate_questions(
        request.job_analysis,
        request.categories,
        request.difficulty_levels,
        request.count_per_category
    )
    return questions
```

### 3. Dependencies

Update the file: `server/src/dependencies.py` by adding:

```python
from src.services.job_description_service import JobDescriptionService

# Cache for services
_job_description_service = None

def get_job_description_service() -> JobDescriptionService:
    """Get or create job description service instance."""
    global _job_description_service
    if _job_description_service is None:
        _job_description_service = JobDescriptionService(get_llm_service())
    return _job_description_service
```

### 4. Register Routes in Main App

Update the file: `server/main.py` by adding:

```python
from src.routes import job_description_routes

# Add this to the existing app routes
app.include_router(job_description_routes.router)
```

## Frontend Implementation

### 1. Job Description Analysis Model

File: `lib/models/job_description_analysis.dart`

```dart
class JobDescriptionAnalysis {
  final List<String> requiredSkills;
  final List<String> desiredSkills;
  final String experienceLevel;
  final List<String> domainKnowledge;
  final List<String> softSkills;
  final List<String> technologies;
  
  JobDescriptionAnalysis({
    required this.requiredSkills,
    required this.desiredSkills,
    required this.experienceLevel,
    required this.domainKnowledge,
    required this.softSkills,
    required this.technologies,
  });
  
  factory JobDescriptionAnalysis.fromJson(Map<String, dynamic> json) {
    return JobDescriptionAnalysis(
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      desiredSkills: List<String>.from(json['desired_skills'] ?? []),
      experienceLevel: json['experience_level'] ?? 'mid',
      domainKnowledge: List<String>.from(json['domain_knowledge'] ?? []),
      softSkills: List<String>.from(json['soft_skills'] ?? []),
      technologies: List<String>.from(json['technologies'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'required_skills': requiredSkills,
      'desired_skills': desiredSkills,
      'experience_level': experienceLevel,
      'domain_knowledge': domainKnowledge,
      'soft_skills': softSkills,
      'technologies': technologies,
    };
  }
}
```

### 2. Job Description Service

File: `lib/services/job_description_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/job_description_analysis.dart';
import '../models/interview_question.dart';
import '../models/app_error.dart';
import '../services/error_service.dart';
import '../utils/constants.dart';
import '../utils/config.dart';
import '../web/proxy.dart';

class JobDescriptionService {
  final ProxyClient client;
  final ErrorService _errorService = ErrorService();

  // Constructor
  JobDescriptionService() : client = ProxyClient(Constants.apiBaseUrl) {
    debugPrint(
      'Job Description Service initialized with server connection: ${Constants.apiBaseUrl}',
    );
  }
  
  // Analyze a job description
  Future<JobDescriptionAnalysis> analyzeJobDescription(String jobDescription) async {
    debugPrint('Analyzing job description...');
    
    try {
      final response = await client
          .post(
            '/api/job-description/analyze',
            body: {'job_description': jobDescription},
          )
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              throw AppError.api(
                'The server took too long to respond',
                code: 'api_timeout',
                severity: ErrorSeverity.warning,
              );
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return JobDescriptionAnalysis.fromJson(responseData);
      } else {
        throw AppError.api(
          'Server returned an error',
          code: 'server_error',
          severity: ErrorSeverity.warning,
          details: 'Status code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      if (e is AppError) {
        _errorService.reportError(e);
        rethrow;
      }
      
      final error = AppError.unknown(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'analyzeJobDescription'},
      );
      _errorService.reportError(error);
      throw error;
    }
  }
  
  // Generate interview questions based on job analysis
  Future<List<InterviewQuestion>> generateQuestions({
    required JobDescriptionAnalysis jobAnalysis,
    required List<String> categories,
    required List<String> difficultyLevels,
    int countPerCategory = 3,
  }) async {
    debugPrint('Generating interview questions...');
    
    try {
      final response = await client
          .post(
            '/api/job-description/generate-questions',
            body: {
              'job_analysis': jobAnalysis.toJson(),
              'categories': categories,
              'difficulty_levels': difficultyLevels,
              'count_per_category': countPerCategory,
            },
          )
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              throw AppError.api(
                'The server took too long to respond',
                code: 'api_timeout',
                severity: ErrorSeverity.warning,
              );
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        
        // Convert to InterviewQuestion objects
        return responseData.map((questionData) {
          return InterviewQuestion(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_${responseData.indexOf(questionData)}',
            text: questionData['text'],
            category: questionData['category'],
            subtopic: questionData['subtopic'],
            difficulty: questionData['difficulty'],
            answer: questionData['answer'],
            isDraft: true, // Mark as draft by default
          );
        }).toList();
      } else {
        throw AppError.api(
          'Server returned an error',
          code: 'server_error',
          severity: ErrorSeverity.warning,
          details: 'Status code: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      if (e is AppError) {
        _errorService.reportError(e);
        rethrow;
      }
      
      final error = AppError.unknown(
        e,
        stackTrace: stackTrace,
        context: {'operation': 'generateQuestions'},
      );
      _errorService.reportError(error);
      throw error;
    }
  }
}
```

### 3. Progress Steps Widget

File: `lib/widgets/progress_steps_widget.dart`

```dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProgressStepsWidget extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const ProgressStepsWidget({
    Key? key,
    required this.steps,
    required this.currentStep,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        // If even index, it's a step
        if (index % 2 == 0) {
          final stepIndex = (index ~/ 2) + 1;
          return Expanded(child: _buildStep(stepIndex, steps[index ~/ 2]));
        } 
        // If odd index, it's a connector
        else {
          return _buildConnector(currentStep > (index ~/ 2) + 1);
        }
      }),
    );
  }

  Widget _buildStep(int step, String label) {
    final isActive = currentStep >= step;
    final isCurrentStep = currentStep == step;
    
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : Colors.grey.shade300,
            border: isCurrentStep
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isActive && !isCurrentStep
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.textPrimary : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? AppColors.primary : Colors.grey.shade300,
    );
  }
}
```

### 4. Loading Overlay Widget

File: `lib/widgets/loading_overlay.dart`

```dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 5. Job Description Question Generator Screen

File: `lib/screens/job_description_question_generator_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job_description_analysis.dart';
import '../models/interview_question.dart';
import '../services/job_description_service.dart';
import '../services/interview_service.dart';
import '../utils/design_system.dart';
import '../utils/colors.dart';
import '../widgets/progress_steps_widget.dart';
import '../widgets/loading_overlay.dart';

class JobDescriptionQuestionGeneratorScreen extends StatefulWidget {
  const JobDescriptionQuestionGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<JobDescriptionQuestionGeneratorScreen> createState() => _JobDescriptionQuestionGeneratorScreenState();
}

class _JobDescriptionQuestionGeneratorScreenState extends State<JobDescriptionQuestionGeneratorScreen> {
  // State variables
  final TextEditingController _jobDescriptionController = TextEditingController();
  int _activeStep = 1; // 1 = Job Description, 2 = Generated Questions, 3 = Review
  bool _isLoading = false;
  String _loadingMessage = '';
  List<InterviewQuestion> _generatedQuestions = [];
  String _searchQuery = '';
  JobDescriptionAnalysis? _jobAnalysis;
  final JobDescriptionService _jobDescriptionService = JobDescriptionService();
  late InterviewService _interviewService;
  
  // Category checkboxes state
  Map<String, bool> _categories = {
    'technical': true,
    'applied': true,
    'behavioral': true,
    'case': true
  };
  
  // Difficulty levels state
  Map<String, bool> _difficultyLevels = {
    'entry': true,
    'mid': true,
    'senior': true
  };
  
  @override
  void initState() {
    super.initState();
    _jobDescriptionController.text = 'Enter your job description here...';
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interviewService = Provider.of<InterviewService>(context);
  }
  
  @override
  void dispose() {
    _jobDescriptionController.dispose();
    super.dispose();
  }
  
  // Toggle category selection
  void _toggleCategory(String category) {
    setState(() {
      _categories[category] = !(_categories[category] ?? false);
    });
  }
  
  // Toggle difficulty level selection
  void _toggleDifficulty(String level) {
    setState(() {
      _difficultyLevels[level] = !(_difficultyLevels[level] ?? false);
    });
  }
  
  // Generate questions from job description
  void _handleGenerateQuestions() async {
    final jobDescription = _jobDescriptionController.text.trim();
    
    if (jobDescription.isEmpty || jobDescription == 'Enter your job description here...') {
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
      _loadingMessage = 'Analyzing job description...';
    });
    
    try {
      // First, analyze the job description
      final jobAnalysis = await _jobDescriptionService.analyzeJobDescription(jobDescription);
      
      if (!mounted) return;
      
      setState(() {
        _loadingMessage = 'Generating questions...';
      });
      
      // Then, generate questions based on the analysis
      final selectedCategories = _categories.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
          
      final selectedDifficulties = _difficultyLevels.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      
      if (selectedCategories.isEmpty || selectedDifficulties.isEmpty) {
        throw Exception('Please select at least one category and difficulty level');
      }
      
      final generatedQuestions = await _jobDescriptionService.generateQuestions(
        jobAnalysis: jobAnalysis,
        categories: selectedCategories,
        difficultyLevels: selectedDifficulties,
        countPerCategory: 3, // Default to 3 questions per category
      );
      
      if (!mounted) return;
      
      setState(() {
        _jobAnalysis = jobAnalysis;
        _generatedQuestions = generatedQuestions;
        _activeStep = 2;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
  
  // Save generated questions
  void _saveQuestionSet() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = 'Saving questions...';
    });
    
    try {
      // Save questions using the interview service
      for (final question in _generatedQuestions) {
        await _interviewService.saveQuestion(question);
      }
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question set saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate back
      Navigator.pop(context);
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
      body: Stack(
        children: [
          _buildContent(),
          if (_isLoading) LoadingOverlay(message: _loadingMessage),
        ],
      ),
    );
  }
  
  Widget _buildContent() {
    if (_activeStep == 1) {
      return _buildJobDescriptionStep();
    } else if (_activeStep == 2) {
      return _buildGeneratedQuestionsStep();
    } else {
      return _buildReviewStep();
    }
  }
  
  // Step 1: Job Description Input
  Widget _buildJobDescriptionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DS.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Steps
          ProgressStepsWidget(
            steps: const ['Job Description', 'Generated Questions', 'Review'],
            currentStep: _activeStep,
          ),
          
          // Job Description Input
          const SizedBox(height: DS.spacingL),
          Text(
            'Paste Job Description',
            style: DS.headingMedium,
          ),
          const SizedBox(height: DS.spacingS),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _jobDescriptionController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Enter your job description here...',
                contentPadding: EdgeInsets.all(DS.spacingM),
                border: InputBorder.none,
              ),
              onTap: () {
                if (_jobDescriptionController.text == 'Enter your job description here...') {
                  _jobDescriptionController.clear();
                }
              },
            ),
          ),
          
          // Categories
          const SizedBox(height: DS.spacingL),
          Text(
            'Categories to Include',
            style: DS.headingMedium,
          ),
          const SizedBox(height: DS.spacingS),
          Wrap(
            spacing: DS.spacingM,
            runSpacing: DS.spacingS,
            children: [
              _buildCategoryCheckbox('technical', 'Technical Knowledge'),
              _buildCategoryCheckbox('applied', 'Applied Skills'),
              _buildCategoryCheckbox('behavioral', 'Behavioral Questions'),
              _buildCategoryCheckbox('case', 'Case Studies'),
            ],
          ),
          
          // Difficulty Levels
          const SizedBox(height: DS.spacingL),
          Text(
            'Difficulty Levels',
            style: DS.headingMedium,
          ),
          const SizedBox(height: DS.spacingS),
          Wrap(
            spacing: DS.spacingM,
            runSpacing: DS.spacingS,
            children: [
              _buildDifficultyCheckbox('entry', 'Entry Level'),
              _buildDifficultyCheckbox('mid', 'Mid Level'),
              _buildDifficultyCheckbox('senior', 'Senior Level'),
            ],
          ),
          
          // Generate Button
          const SizedBox(height: DS.spacingXL),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _handleGenerateQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: DS.spacingL,
                  vertical: DS.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                ),
              ),
              child: const Text('Generate Questions'),
            ),
          ),
        ],
      ),
    );
  }
  
  // Step 2: Generated Questions
  Widget _buildGeneratedQuestionsStep() {
    // Filter questions based on search query
    final filteredQuestions = _generatedQuestions
        .where((q) => q.text.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
        
    return Column(
      children: [
        // Progress Steps
        Padding(
          padding: const EdgeInsets.all(DS.spacingL),
          child: ProgressStepsWidget(
            steps: const ['Job Description', 'Generated Questions', 'Review'],
            currentStep: _activeStep,
          ),
        ),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DS.spacingL),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search questions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: DS.spacingS),
            ),
          ),
        ),
        
        const SizedBox(height: DS.spacingM),
        
        // Questions list
        Expanded(
          child: filteredQuestions.isEmpty
              ? const Center(child: Text('No questions match your search.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(DS.spacingL),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: DS.spacingM),
                  itemBuilder: (context, index) {
                    final question = filteredQuestions[index];
                    return _buildQuestionCard(question);
                  },
                ),
        ),
        
        // Action buttons
        Container(
          padding: const EdgeInsets.all(DS.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activeStep = 1;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DS.spacingL,
                    vertical: DS.spacingM,
                  ),
                ),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activeStep = 3;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DS.spacingL,
                    vertical: DS.spacingM,
                  ),
                ),
                child: const Text('Review and Save'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Step 3: Review
  Widget _buildReviewStep() {
    // Count questions by category and difficulty
    final categoryCounts = <String, int>{};
    final difficultyCounts = <String, int>{};
    int starredCount = 0;
    
    for (final question in _generatedQuestions) {
      categoryCounts[question.category] = (categoryCounts[question.category] ?? 0) + 1;
      difficultyCounts[question.difficulty] = (difficultyCounts[question.difficulty] ?? 0) + 1;
      if (question.isStarred) starredCount++;
    }
    
    return Column(
      children: [
        // Progress Steps
        Padding(
          padding: const EdgeInsets.all(DS.spacingL),
          child: ProgressStepsWidget(
            steps: const ['Job Description', 'Generated Questions', 'Review'],
            currentStep: _activeStep,
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DS.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(DS.spacingL),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: DS.headingMedium,
                      ),
                      const SizedBox(height: DS.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Total Questions',
                              '${_generatedQuestions.length}',
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Categories',
                              '${categoryCounts.length}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DS.spacingM),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              'Difficulty Levels',
                              '${difficultyCounts.length}',
                            ),
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              'Starred Questions',
                              '$starredCount',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Preview of questions
                const SizedBox(height: DS.spacingL),
                Text(
                  'Generated Questions',
                  style: DS.headingMedium,
                ),
                const SizedBox(height: DS.spacingM),
                
                ..._generatedQuestions.take(3).map((question) => 
                  _buildQuestionPreview(_generatedQuestions.indexOf(question), question)
                ),
                
                if (_generatedQuestions.length > 3) ...[
                  const SizedBox(height: DS.spacingM),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _activeStep = 2;
                        });
                      },
                      child: const Text('View All Questions'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Action buttons
        Container(
          padding: const EdgeInsets.all(DS.spacingL),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _activeStep = 2;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DS.spacingL,
                    vertical: DS.spacingM,
                  ),
                ),
                child: const Text('Edit Questions'),
              ),
              ElevatedButton(
                onPressed: _saveQuestionSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DS.spacingL,
                    vertical: DS.spacingM,
                  ),
                ),
                child: const Text('Save Question Set'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper widgets
  
  Widget _buildCategoryCheckbox(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _categories[key] ?? false,
          onChanged: (value) => _toggleCategory(key),
          activeColor: AppColors.primary,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDifficultyCheckbox(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _difficultyLevels[key] ?? false,
          onChanged: (value) => _toggleDifficulty(key),
          activeColor: AppColors.primary,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionCard(InterviewQuestion question) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DS.borderRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(DS.spacingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _toggleStar(question.id),
                  icon: Icon(
                    question.isStarred ? Icons.star : Icons.star_border,
                    color: question.isStarred ? Colors.amber : Colors.grey.shade400,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DS.spacingM),
            child: Wrap(
              spacing: DS.spacingS,
              runSpacing: DS.spacingXs,
              children: [
                _buildCategoryTag(question.category),
                _buildSubtopicTag(question.subtopic),
                _buildDifficultyTag(question.difficulty),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(DS.spacingM),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to practice screen for this question
                    // This would be implemented in a real app
                  },
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Practice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DS.spacingS,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DS.borderRadiusXsmall),
                    ),
                  ),
                ),
                const SizedBox(width: DS.spacingM),
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
                    // Edit question functionality would be implemented in a real app
                  },
                  icon: Icon(
                    Icons.edit,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionPreview(int index, InterviewQuestion question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: DS.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: DS.spacingS),
                Wrap(
                  spacing: DS.spacingS,
                  runSpacing: DS.spacingXs,
                  children: [
                    _buildCategoryTag(question.category, isSmall: true),
                    _buildDifficultyTag(question.difficulty, isSmall: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryTag(String category, {bool isSmall = false}) {
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
        label = 'Behavioral';
        backgroundColor = Colors.yellow.shade100;
        break;
      case 'case':
        label = 'Case Study';
        backgroundColor = Colors.purple.shade100;
        break;
      default:
        label = 'Other';
        backgroundColor = Colors.grey.shade100;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : DS.spacingS,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
  
  Widget _buildSubtopicTag(String subtopic) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DS.spacingS,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
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
  
  Widget _buildDifficultyTag(String difficulty, {bool isSmall = false}) {
    String label;
    Color backgroundColor;
    Color textColor;
    
    switch (difficulty) {
      case 'entry':
        label = 'Entry Level';
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case 'mid':
        label = 'Mid Level';
        backgroundColor = Colors.yellow.shade50;
        textColor = Colors.yellow.shade700;
        break;
      case 'senior':
        label = 'Senior Level';
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      default:
        label = 'Unknown';
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : DS.spacingS,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: backgroundColor.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
```

### 6. Update the FAB in Interview Questions Screen

Modify the file: `lib/screens/interview_questions_screen.dart`

```dart
// Add this import
import '../screens/job_description_question_generator_screen.dart';

// In the build method of InterviewQuestionsScreen, replace the existing FloatingActionButton
floatingActionButton: FloatingActionButton(
  onPressed: () {
    // Show menu options when the FAB is pressed
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: const Text('Create New Question'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateInterviewQuestionScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description, color: AppColors.primary),
              title: const Text('Generate from Job Description'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JobDescriptionQuestionGeneratorScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.primary),
              title: const Text('Import Questions'),
              onTap: () {
                Navigator.pop(context);
                // Handle import functionality
              },
            ),
          ],
        ),
      ),
    );
  },
  tooltip: 'Add new questions',
  backgroundColor: AppColors.primary,
  child: const Icon(Icons.add),
),
```

### 7. Update Routes in Main App

File: `lib/main.dart`

```dart
// Add this import
import 'screens/job_description_question_generator_screen.dart';

// In your routes definition, add:
routes: {
  '/': (context) => const HomeScreen(),
  '/interview-questions': (context) => const InterviewQuestionsScreen(),
  '/job-description-generator': (context) => const JobDescriptionQuestionGeneratorScreen(),
  // ... other routes
},
```

## Implementation Steps

1. **Backend Implementation**:
   - Create the job description service in the server
   - Add API routes for analyzing job descriptions and generating questions
   - Update dependencies and register routes in the main app

2. **Frontend Implementation**:
   - Create the model for job description analysis
   - Add the job description service for API communication
   - Create the widgets for progress steps and loading overlay
   - Implement the main screen for the job description question generator
   - Update the FAB in the interview questions screen
   - Register the new route in the main app

3. **Testing**:
   - Test the job description analysis with various job descriptions
   - Test question generation for different categories and difficulty levels
   - Test saving generated questions

## Troubleshooting

If you encounter issues:

1. **Server integration issues**:
   - Make sure the LLM service is properly initialized
   - Check API endpoints are correctly registered
   - Verify proper error handling

2. **Client-side issues**:
   - Check for proper imports
   - Verify state management
   - Test API communication
   - Debug UI rendering