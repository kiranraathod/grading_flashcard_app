"""
API routes for interview question grading operations.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, validator
from typing import List, Optional
import traceback
from src.controllers.interview_grading_controller import InterviewGradingController
import logging

# Set up logger
logger = logging.getLogger(__name__)

# Define the request and response models
class InterviewGradeRequest(BaseModel):
    questionId: str
    questionText: str
    userAnswer: str
    category: str
    difficulty: str

class InterviewGradeResponse(BaseModel):
    score: int
    feedback: str
    suggestions: List[str]

# Create the router
router = APIRouter()

# Create a dependency for the interview grading controller
def get_interview_grading_controller():
    """Dependency to get an InterviewGradingController instance."""
    return InterviewGradingController()

@router.post("/interview-grade", response_model=InterviewGradeResponse)
async def grade_interview_answer(
    request: InterviewGradeRequest,
    controller: InterviewGradingController = Depends(get_interview_grading_controller)
):
    """
    Grade a user's answer to an interview question.
    
    Args:
        request: The grading request containing question details and user answer
        controller: The interview grading controller dependency
        
    Returns:
        InterviewGradeResponse with score, feedback, and suggestions
        
    Raises:
        HTTPException: If an error occurs during grading
    """
    try:
        logger.debug(f"Received interview grading request: {request}")
        
        result = await controller.grade_interview_answer(
            question_id=request.questionId,
            question_text=request.questionText,
            user_answer=request.userAnswer,
            question_category=request.category,
            question_difficulty=request.difficulty
        )
        
        logger.debug(f"Interview grading result: {result}")
        
        # Return the response
        return InterviewGradeResponse(
            score=result["score"],
            feedback=result["feedback"],
            suggestions=result["suggestions"]
        )
        
    except Exception as e:
        logger.error(f"Error in grade_interview_answer endpoint: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred during interview answer grading: {str(e)}"
        )
