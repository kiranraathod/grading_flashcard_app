from fastapi import APIRouter, Depends, HTTPException
from src.models.schema import GradeRequest, GradeResponse, SuggestionRequest, SuggestionResponse, FeedbackRequest, FeedbackResponse
from src.controllers.grading_controller import GradingController
import logging
import traceback

# Set up logger
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

router = APIRouter()

# Create a dependency for the grading controller
def get_grading_controller():
    return GradingController()

@router.post("/grade", response_model=GradeResponse)
async def grade_answer(
    request: GradeRequest, 
    controller: GradingController = Depends(get_grading_controller)
):
    try:
        logger.debug(f"Received grading request: {request.dict()}")
        
        logger.debug("Calling grading controller...")
        try:
            result = await controller.grade_answer(
                request.flashcardId, 
                request.question, 
                request.userAnswer
            )
            logger.debug(f"Grading result: {result}")
            
            # Validate the response structure
            if 'grade' not in result or 'feedback' not in result or 'suggestions' not in result:
                logger.error(f"Invalid response structure: {result}")
                return GradeResponse(
                    grade='F',
                    feedback='Error in grading system. Please try again.',
                    suggestions=['Contact support if this error persists.'],
                    error='Invalid response structure'
                )
            
            return result
        except Exception as inner_e:
            logger.error(f"Error in grading controller: {str(inner_e)}")
            logger.error(traceback.format_exc())
            return GradeResponse(
                grade='F',
                feedback='Error in grading system. Please try again.',
                suggestions=['Contact support if this error persists.'],
                error=str(inner_e)
            )
            
    except Exception as e:
        logger.error(f"Error in grade_answer endpoint: {str(e)}")
        logger.error(traceback.format_exc())
        raise HTTPException(
            status_code=500, 
            detail="An error occurred during grading"
        )

@router.get("/suggestions", response_model=SuggestionResponse)
async def get_suggestions(
    flashcardId: str,
    controller: GradingController = Depends(get_grading_controller)
):
    try:
        logger.debug(f"Received suggestions request for flashcard_id={flashcardId}")
        
        if not flashcardId:
            logger.error("Missing flashcardId parameter")
            raise HTTPException(status_code=400, detail="Missing flashcardId parameter")
        
        result = await controller.get_suggestions(flashcardId)
        logger.debug(f"Returning suggestions: {result}")
        
        return result
    except Exception as e:
        logger.error(f"Error in get_suggestions: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/feedback", response_model=FeedbackResponse)
async def submit_feedback(
    request: FeedbackRequest,
    controller: GradingController = Depends(get_grading_controller)
):
    try:
        logger.debug(f"Received feedback submission: {request.dict()}")
        
        await controller.submit_feedback(
            request.flashcardId, 
            request.userFeedback
        )
        
        return FeedbackResponse(status="success")
    except Exception as e:
        logger.error(f"Error in submit_feedback: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
