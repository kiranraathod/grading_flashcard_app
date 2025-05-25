"""
Routes for serving default application data.
"""
from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import JSONResponse
import logging
from typing import List, Dict, Any, Optional

from ..services.default_data_service import DefaultDataService
from ..models.default_data import (
    DefaultFlashcardSetResponse,
    DefaultInterviewQuestionResponse,
    DefaultCategoryResponse,
    CategoryCountsResponse,
    DefaultDataResponse
)

# Configure logging
logger = logging.getLogger(__name__)

# Create router
router = APIRouter(prefix="/api/default-data", tags=["default-data"])

# Dependency to get the default data service
def get_default_data_service() -> DefaultDataService:
    return DefaultDataService()

@router.get("/", response_model=DefaultDataResponse)
async def get_all_default_data(
    user_id: Optional[str] = None,
    service: DefaultDataService = Depends(get_default_data_service)
):
    """
    Get all default data in a single response.
    This is the main endpoint for initial app data loading.
    """
    try:
        logger.info(f"Fetching all default data for user_id: {user_id}")
        
        # Get all default data
        flashcard_sets = await service.get_default_flashcard_sets(user_id)
        interview_questions = await service.get_default_interview_questions(user_id)
        categories = await service.get_default_categories()
        category_counts = await service.get_category_counts(user_id)
        
        response = DefaultDataResponse(
            flashcard_sets=flashcard_sets,
            interview_questions=interview_questions,
            categories=categories,
            category_counts=category_counts,
            user_id=user_id,
            version="1.0.0"
        )
        
        logger.info(f"Successfully fetched all default data: {len(flashcard_sets)} sets, "
                   f"{len(interview_questions)} questions, {len(categories)} categories")
        
        return response
        
    except Exception as e:
        logger.error(f"Error fetching all default data: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch default data")

@router.get("/flashcard-sets", response_model=List[DefaultFlashcardSetResponse])
async def get_default_flashcard_sets(
    user_id: Optional[str] = None,
    service: DefaultDataService = Depends(get_default_data_service)
):
    """
    Get default flashcard sets.
    """
    try:
        logger.info(f"Fetching default flashcard sets for user_id: {user_id}")
        
        flashcard_sets = await service.get_default_flashcard_sets(user_id)
        
        logger.info(f"Successfully fetched {len(flashcard_sets)} default flashcard sets")
        return flashcard_sets
        
    except Exception as e:
        logger.error(f"Error fetching default flashcard sets: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch default flashcard sets")

@router.get("/interview-questions", response_model=List[DefaultInterviewQuestionResponse])
async def get_default_interview_questions(
    user_id: Optional[str] = None,
    category: Optional[str] = None,
    difficulty: Optional[str] = None,
    service: DefaultDataService = Depends(get_default_data_service)
):
    """
    Get default interview questions with optional filtering.
    """
    try:
        logger.info(f"Fetching default interview questions for user_id: {user_id}, "
                   f"category: {category}, difficulty: {difficulty}")
        
        interview_questions = await service.get_default_interview_questions(
            user_id=user_id,
            category=category,
            difficulty=difficulty
        )
        
        logger.info(f"Successfully fetched {len(interview_questions)} default interview questions")
        return interview_questions
        
    except Exception as e:
        logger.error(f"Error fetching default interview questions: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch default interview questions")

@router.get("/categories", response_model=List[DefaultCategoryResponse])
async def get_default_categories(
    service: DefaultDataService = Depends(get_default_data_service)
):
    """
    Get available categories with their subtopics.
    """
    try:
        logger.info("Fetching default categories")
        
        categories = await service.get_default_categories()
        
        logger.info(f"Successfully fetched {len(categories)} default categories")
        return categories
        
    except Exception as e:
        logger.error(f"Error fetching default categories: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch default categories")

@router.get("/category-counts", response_model=CategoryCountsResponse)
async def get_category_counts(
    user_id: Optional[str] = None,
    service: DefaultDataService = Depends(get_default_data_service)
):
    """
    Get dynamic category counts based on available questions.
    """
    try:
        logger.info(f"Fetching category counts for user_id: {user_id}")
        
        category_counts = await service.get_category_counts(user_id)
        
        logger.info(f"Successfully fetched category counts for {len(category_counts.counts)} categories")
        return category_counts
        
    except Exception as e:
        logger.error(f"Error fetching category counts: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch category counts")

@router.get("/health")
async def default_data_health_check():
    """
    Health check endpoint for default data service.
    """
    try:
        service = DefaultDataService()
        
        # Basic validation - check if we can fetch categories
        categories = await service.get_default_categories()
        
        return {
            "status": "healthy",
            "service": "default-data",
            "categories_available": len(categories),
            "version": "1.0.0"
        }
    except Exception as e:
        logger.error(f"Default data service health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail="Default data service unavailable")
