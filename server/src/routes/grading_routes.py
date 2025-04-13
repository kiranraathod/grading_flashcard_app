"""
API routes for flashcard grading operations.
"""
from fastapi import APIRouter, Depends, HTTPException
from src.models.schema import GradeRequest, GradeResponse, SuggestionRequest, SuggestionResponse, FeedbackRequest, FeedbackResponse
from src.controllers.grading_controller import GradingController
from src.utils.exceptions import BaseFlashcardAPIError, InvalidInputError, ResourceNotFoundError
import logging
import traceback

# Set up logger
logger = logging.getLogger(__name__)

router = APIRouter()

# Create a dependency for the grading controller
def get_grading_controller():
    """Dependency to get a GradingController instance."""
    return GradingController()

@router.post("/grade", response_model=GradeResponse)
async def grade_answer(
    request: GradeRequest, 
    controller: GradingController = Depends(get_grading_controller)
):
    """
    Grade a user's answer to a flashcard question.
    
    Args:
        request: The grading request containing flashcardId, question, and userAnswer
        controller: The grading controller dependency
        
    Returns:
        GradeResponse with grade, feedback, and suggestions
        
    Raises:
        HTTPException: If an error occurs during grading
    """
    try:
        logger.debug(f"Received grading request: {request}")
        
        logger.debug("Calling grading controller...")
        result = await controller.grade_answer(
            request.flashcardId, 
            request.question, 
            request.userAnswer,
            request.correctAnswer
        )
        logger.debug(f"Grading result: {result}")
        
        # Validate the response structure
        if 'grade' not in result or 'feedback' not in result or 'suggestions' not in result:
            logger.error(f"Invalid response structure: {result}")
            return GradeResponse(
                grade='X',
                feedback='Error in grading system. Please try again.',
                suggestions=['Contact support if this error persists.'],
                error='invalid_response_structure'
            )
        
        return result
    except BaseFlashcardAPIError as api_error:
        # Handle our custom exceptions
        logger.error(f"API error in grade_answer: {str(api_error)}")
        raise HTTPException(
            status_code=api_error.status_code, 
            detail=api_error.message
        )
    except Exception as e:
        logger.error(f"Unexpected error in grade_answer endpoint: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=500, 
            detail=f"An unexpected error occurred during grading: {str(e)}"
        )

@router.post("/suggestions", response_model=SuggestionResponse)
async def get_suggestions(
    request: SuggestionRequest,
    controller: GradingController = Depends(get_grading_controller)
):
    """
    Get improvement suggestions for a specific flashcard.
    
    Args:
        request: The suggestions request containing flashcardId
        controller: The grading controller dependency
        
    Returns:
        SuggestionResponse with suggestions for the flashcard
        
    Raises:
        HTTPException: If an error occurs while getting suggestions
    """
    try:
        logger.debug(f"Received suggestions request: {request}")
        
        if not request.flashcardId:
            logger.error("Missing flashcardId parameter")
            raise InvalidInputError("Missing flashcardId parameter")
        
        result = await controller.get_suggestions(request.flashcardId)
        logger.debug(f"Returning suggestions: {result}")
        
        return result
    except BaseFlashcardAPIError as api_error:
        logger.error(f"API error in get_suggestions: {str(api_error)}")
        raise HTTPException(
            status_code=api_error.status_code, 
            detail=api_error.message
        )
    except Exception as e:
        logger.error(f"Unexpected error in get_suggestions: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=500, 
            detail=f"An unexpected error occurred while getting suggestions: {str(e)}"
        )

@router.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(
    request: FeedbackRequest,
    controller: GradingController = Depends(get_grading_controller)
):
    """
    Submit user feedback on the grading process.
    
    Args:
        request: The feedback request containing flashcardId and userFeedback
        controller: The grading controller dependency
        
    Returns:
        FeedbackResponse indicating success
        
    Raises:
        HTTPException: If an error occurs while submitting feedback
    """
    try:
        logger.debug(f"Received feedback submission: {request}")
        
        await controller.submit_feedback(
            request.flashcardId, 
            request.userFeedback
        )
        
        return FeedbackResponse(status="success", message="Feedback submitted successfully")
    except BaseFlashcardAPIError as api_error:
        logger.error(f"API error in submit_feedback: {str(api_error)}")
        raise HTTPException(
            status_code=api_error.status_code, 
            detail=api_error.message
        )
    except Exception as e:
        logger.error(f"Unexpected error in submit_feedback: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=500, 
            detail=f"An unexpected error occurred while submitting feedback: {str(e)}"
        )
