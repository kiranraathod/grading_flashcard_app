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

class InterviewBatchGradeRequest(BaseModel):
    answers: List[InterviewGradeRequest]
    
    @validator('answers')
    def validate_answers(cls, v):
        if not v or len(v) == 0:
            raise ValueError("answers list cannot be empty")
        return v

class BatchGradeResponseItem(InterviewGradeResponse):
    questionId: str

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

@router.post("/interview-grade-batch", response_model=List[BatchGradeResponseItem])
async def grade_interview_answers_batch(
    request: InterviewBatchGradeRequest,
    controller: InterviewGradingController = Depends(get_interview_grading_controller)
):
    """
    Grade multiple interview answers in a batch.
    
    Args:
        request: Batch grading request containing a list of answers
        controller: The interview grading controller dependency
        
    Returns:
        List of grading responses
    """
    try:
        logger.debug(f"Received batch grading request with {len(request.answers)} items")
        
        results = []
        for item in request.answers:
            # Process each answer
            logger.debug(f"Grading answer for question {item.questionId}")
            
            try:
                # Grade the individual answer
                result = await controller.grade_interview_answer(
                    question_id=item.questionId,
                    question_text=item.questionText,
                    user_answer=item.userAnswer,
                    question_category=item.category,
                    question_difficulty=item.difficulty
                )
                
                # Add question ID to result for client-side matching
                result["questionId"] = item.questionId
                
                # Add to results list
                results.append(result)
                
            except Exception as item_error:
                # Log the error but continue processing other items
                logger.error(f"Error grading question {item.questionId}: {str(item_error)}")
                logger.error(traceback.format_exc())
                
                # Continue with the next item instead of using a fallback
                continue
        
        logger.info(f"Batch grading completed for {len(results)} answers")
        return results
        
    except Exception as e:
        logger.error(f"Error in batch grading endpoint: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred during batch grading: {str(e)}"
        )
