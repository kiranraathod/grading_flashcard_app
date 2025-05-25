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
            description="Python fundamentals",
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
        """Get default interview questions - simplified version."""
        logger.info(f"Generating interview questions for user: {user_id}")
        
        questions = [
            DefaultInterviewQuestionResponse(
                id="1", text="Explain machine learning bias and variance",
                category="technical", subtopic="ML Algorithms", difficulty="mid",
                answer="Bias is error from oversimplification, variance is error from sensitivity to data.",
                user_id=user_id, category_id="technical"
            ),
            DefaultInterviewQuestionResponse(
                id="2", text="How do you handle missing data?",
                category="applied", subtopic="Data Preprocessing", difficulty="entry",
                answer="Identify patterns, evaluate extent, choose imputation strategy, validate approach.",
                user_id=user_id, category_id="applied"
            )
        ]
        
        # Apply filters
        if category:
            questions = [q for q in questions if q.category == category]
        if difficulty:
            questions = [q for q in questions if q.difficulty == difficulty]
            
        return questions
    async def get_default_categories(self) -> List[DefaultCategoryResponse]:
        """Get available categories."""
        categories = [
            DefaultCategoryResponse(
                id="technical", name="Technical Knowledge", color="#E3F2FD", icon="article",
                subtopics=["Machine Learning Algorithms", "SQL & Database", "Python Fundamentals"]
            ),
            DefaultCategoryResponse(
                id="applied", name="Applied Skills", color="#E8F5E8", icon="build",
                subtopics=["Data Cleaning & Preprocessing", "Model Evaluation", "Feature Engineering"]
            ),
            DefaultCategoryResponse(
                id="behavioral", name="Behavioral Questions", color="#FFFDE7", icon="people",
                subtopics=["Communication Skills", "Teamwork", "Problem Solving"]
            ),
        ]
        return categories

    async def get_category_counts(self, user_id: Optional[str] = None) -> CategoryCountsResponse:
        """Get dynamic category counts."""
        # Replace hardcoded counts from home screen
        counts = {
            "Data Analysis": 18,
            "Web Development": 15, 
            "Machine Learning": 22,
            "SQL": 10,
            "Python": 14,
            "Statistics": 8,
        }
        
        return CategoryCountsResponse(
            counts=counts,
            total_questions=sum(counts.values()),
            user_id=user_id,
            last_updated=datetime.now()
        )
