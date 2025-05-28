"""
Service for providing default application data.
This service converts hardcoded client data into server-provided responses
while maintaining compatibility with future Supabase integration.
"""
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from ..models.default_data import (
    DefaultFlashcardSetResponse,
    DefaultFlashcardResponse,
    DefaultInterviewQuestionResponse,
    DefaultCategoryResponse,
    CategoryCountsResponse
)

logger = logging.getLogger(__name__)

class DefaultDataService:
    """Service for managing default application data."""

    def __init__(self):
        """Initialize the default data service."""
        logger.info("DefaultDataService initialized")




    async def get_default_flashcard_sets(self, user_id: Optional[str] = None) -> List[DefaultFlashcardSetResponse]:
        """Get default flashcard sets - simplified version."""
        logger.info(f"Generating default flashcard sets for user_id: {user_id}")
        
        # Create a simple Python Basics set
        flashcards = []
        questions = [
            ("1", "What is Python?", "Python is a high-level programming language."),
            ("2", "How do you print in Python?", 'print("Hello World")'),
            ("3", "How do you comment in Python?", "Use # for single line comments"),
        ]
        
        for qid, q, a in questions:
            flashcards.append(DefaultFlashcardResponse(
                id=qid, question=q, answer=a, is_completed=False,
                user_id=user_id, category_id="python"
            ))
        
        sets = [DefaultFlashcardSetResponse(
            id="python-basics-001",
            title="Python Basics",
            description="",  # Empty description
            is_draft=False,
            rating=4.5,
            rating_count=12,
            flashcards=flashcards,
            user_id=user_id,
            category_id="python"
        )]
        
        return sets

    async def get_default_interview_questions(
        self, user_id: Optional[str] = None, category: Optional[str] = None, 
        difficulty: Optional[str] = None
    ) -> List[DefaultInterviewQuestionResponse]:
        """Get exactly 6 subtopics with 3 questions each (18 total questions)."""
        logger.info(f"Generating interview questions for user: {user_id}")
        
        # UPDATED: Exactly 6 subtopics with 3 questions each = 18 total questions
        questions = [
            # Data Analysis Subtopic (3 questions)
            DefaultInterviewQuestionResponse(
                id="data-analysis-1", text="How would you handle missing data in a dataset?",
                category="applied", subtopic="Data Analysis", difficulty="entry",
                answer="Identify patterns, evaluate extent, choose imputation strategy, validate approach.",
                user_id=user_id, category_id="data_analysis"
            ),
            DefaultInterviewQuestionResponse(
                id="data-analysis-2", text="Explain the difference between correlation and causation",
                category="applied", subtopic="Data Analysis", difficulty="entry",
                answer="Correlation indicates relationship strength, causation implies direct cause-effect relationship.",
                user_id=user_id, category_id="data_analysis"
            ),
            DefaultInterviewQuestionResponse(
                id="data-analysis-3", text="How do you detect outliers in data?",
                category="applied", subtopic="Data Analysis", difficulty="mid",
                answer="Use statistical methods like IQR, Z-score, or visualization techniques like box plots.",
                user_id=user_id, category_id="data_analysis"
            ),

            # Machine Learning Subtopic (3 questions)
            DefaultInterviewQuestionResponse(
                id="ml-1", text="Explain machine learning bias and variance",
                category="technical", subtopic="Machine Learning", difficulty="mid",
                answer="Bias is error from oversimplification, variance is error from sensitivity to data.",
                user_id=user_id, category_id="machine_learning"
            ),
            DefaultInterviewQuestionResponse(
                id="ml-2", text="What is overfitting and how do you prevent it?",
                category="technical", subtopic="Machine Learning", difficulty="mid",
                answer="Overfitting occurs when model memorizes training data. Prevent with regularization, cross-validation.",
                user_id=user_id, category_id="machine_learning"
            ),
            DefaultInterviewQuestionResponse(
                id="ml-3", text="Explain the difference between supervised and unsupervised learning",
                category="technical", subtopic="Machine Learning", difficulty="entry",
                answer="Supervised uses labeled data for prediction, unsupervised finds patterns in unlabeled data.",
                user_id=user_id, category_id="machine_learning"
            ),

            # SQL Database Subtopic (3 questions)
            DefaultInterviewQuestionResponse(
                id="sql-1", text="Explain the difference between INNER JOIN and LEFT JOIN",
                category="technical", subtopic="SQL Database", difficulty="entry",
                answer="INNER JOIN returns only matching records, LEFT JOIN returns all left table records.",
                user_id=user_id, category_id="sql"
            ),
            DefaultInterviewQuestionResponse(
                id="sql-2", text="What is a subquery and when would you use it?",
                category="technical", subtopic="SQL Database", difficulty="mid",
                answer="Query nested inside another query, useful for complex filtering and calculations.",
                user_id=user_id, category_id="sql"
            ),
            DefaultInterviewQuestionResponse(
                id="sql-3", text="How do you optimize a slow SQL query?",
                category="technical", subtopic="SQL Database", difficulty="senior",
                answer="Add indexes, analyze execution plan, rewrite joins, limit result sets, update statistics.",
                user_id=user_id, category_id="sql"
            ),

            # Python Programming Subtopic (3 questions)
            DefaultInterviewQuestionResponse(
                id="python-1", text="What are Python decorators?",
                category="technical", subtopic="Python Programming", difficulty="mid",
                answer="Functions that modify or extend behavior of other functions without changing their code.",
                user_id=user_id, category_id="python"
            ),
            DefaultInterviewQuestionResponse(
                id="python-2", text="Explain list comprehensions in Python",
                category="technical", subtopic="Python Programming", difficulty="entry",
                answer="Concise way to create lists using syntax: [expression for item in iterable if condition]",
                user_id=user_id, category_id="python"
            ),
            DefaultInterviewQuestionResponse(
                id="python-3", text="What is the difference between == and is in Python?",
                category="technical", subtopic="Python Programming", difficulty="entry",
                answer="== compares values, 'is' compares object identity (memory location).",
                user_id=user_id, category_id="python"
            ),

            # API Development Subtopic (3 questions)
            DefaultInterviewQuestionResponse(
                id="web-1", text="What is RESTful API design?",
                category="technical", subtopic="API Development", difficulty="mid",
                answer="Architectural style using HTTP methods for stateless, scalable web services.",
                user_id=user_id, category_id="web_development"
            ),
            DefaultInterviewQuestionResponse(
                id="web-2", text="Explain the difference between GET and POST requests",
                category="technical", subtopic="API Development", difficulty="entry",
                answer="GET retrieves data (idempotent), POST sends data to server (may cause changes).",
                user_id=user_id, category_id="web_development"
            ),
            DefaultInterviewQuestionResponse(
                id="web-3", text="What is CORS and why is it important?",
                category="technical", subtopic="API Development", difficulty="mid",
                answer="Cross-Origin Resource Sharing - security feature that controls cross-domain requests.",
                user_id=user_id, category_id="web_development"
            ),

            # Statistics Subtopic (3 questions)
            DefaultInterviewQuestionResponse(
                id="stats-1", text="What is the central limit theorem?",
                category="technical", subtopic="Statistics", difficulty="mid",
                answer="Sample means approach normal distribution as sample size increases, regardless of population distribution.",
                user_id=user_id, category_id="statistics"
            ),
            DefaultInterviewQuestionResponse(
                id="stats-2", text="Explain Type I and Type II errors",
                category="technical", subtopic="Statistics", difficulty="mid",
                answer="Type I: false positive (reject true null), Type II: false negative (accept false null).",
                user_id=user_id, category_id="statistics"
            ),
            DefaultInterviewQuestionResponse(
                id="stats-3", text="What is p-value and how do you interpret it?",
                category="technical", subtopic="Statistics", difficulty="entry",
                answer="Probability of observing results at least as extreme as observed, assuming null hypothesis is true.",
                user_id=user_id, category_id="statistics"
            ),
        ]
        
        # Apply filters
        if category:
            questions = [q for q in questions if q.category == category]
        if difficulty:
            questions = [q for q in questions if q.difficulty == difficulty]
            
        return questions
    async def get_default_categories(self) -> List[DefaultCategoryResponse]:
        """Generate categories dynamically from available questions - TRULY DYNAMIC."""
        logger.info("Generating categories dynamically from question data")
        
        # Get all questions to derive categories from actual data
        questions = await self.get_default_interview_questions()
        
        # Extract unique categories from questions
        category_data = {}
        for question in questions:
            # Use category_id as the primary category identifier for UI
            ui_category = getattr(question, 'category_id', question.category)
            if ui_category not in category_data:
                category_data[ui_category] = {
                    'subtopics': set(),
                    'question_count': 0,
                    'difficulties': set()
                }
            category_data[ui_category]['subtopics'].add(question.subtopic)
            category_data[ui_category]['question_count'] += 1
            category_data[ui_category]['difficulties'].add(question.difficulty)
        
        # Category display name mapping
        display_names = {
            'data_analysis': 'Data Analysis',
            'machine_learning': 'Machine Learning', 
            'sql': 'SQL',
            'python': 'Python',
            'web_development': 'Web Development',
            'statistics': 'Statistics',
            'technical': 'Technical Knowledge',
            'applied': 'Applied Skills',
            'behavioral': 'Behavioral Questions',
            'case': 'Case Studies',
            'job': 'Job-Specific'
        }
        
        # Generate category responses with proper metadata
        categories = []
        for category_id, data in category_data.items():
            display_name = display_names.get(category_id, category_id.replace('_', ' ').title())
            categories.append(DefaultCategoryResponse(
                id=category_id,
                name=display_name,
                subtopics=list(data['subtopics'])
            ))
        
        logger.info(f"Generated {len(categories)} categories from {len(questions)} questions")
        return categories

    async def get_category_counts(self, user_id: Optional[str] = None) -> CategoryCountsResponse:
        """Calculate category counts from actual question data - TRULY DYNAMIC."""
        logger.info(f"Calculating dynamic category counts for user: {user_id}")
        
        # Get all available questions
        questions = await self.get_default_interview_questions(user_id=user_id)
        
        # Count questions by UI category (using category_id field)
        counts = {}
        ui_category_mapping = {
            'data_analysis': 'Data Analysis',
            'machine_learning': 'Machine Learning',
            'sql': 'SQL', 
            'python': 'Python',
            'web_development': 'Web Development',
            'statistics': 'Statistics',
            # Legacy support for existing categories
            'technical': 'Technical Knowledge',
            'applied': 'Applied Skills',
            'behavioral': 'Behavioral Questions',
            'case': 'Case Studies',
            'job': 'Job-Specific'
        }
        
        for question in questions:
            # Use category_id as primary, fallback to category
            category_key = getattr(question, 'category_id', question.category)
            ui_category = ui_category_mapping.get(category_key, category_key.replace('_', ' ').title())
            counts[ui_category] = counts.get(ui_category, 0) + 1
        
        # Ensure all expected UI categories are present (even with 0 count)
        expected_categories = [
            'Data Analysis', 'Web Development', 'Machine Learning', 
            'SQL', 'Python', 'Statistics'
        ]
        for ui_cat in expected_categories:
            if ui_cat not in counts:
                counts[ui_cat] = 0
        
        total_questions = sum(counts.values())
        logger.info(f"Dynamic count calculation: {counts}, total: {total_questions}")
        
        return CategoryCountsResponse(
            counts=counts,
            total_questions=total_questions,
            user_id=user_id,
            last_updated=datetime.now()
        )
