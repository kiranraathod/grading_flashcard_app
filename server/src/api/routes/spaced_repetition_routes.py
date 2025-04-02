from fastapi import APIRouter, Request, Depends, HTTPException, status, Query
from src.services.supabase_service import SupabaseService
from src.api.middleware.auth_middleware import StrictAuthRequired, get_current_user
from src.api.models.models import CardProgressRequest, LearningStats, DueCardsResponse
from src.utils.error_handler import AuthenticationError
import logging

# Set up logger
logger = logging.getLogger(__name__)

router = APIRouter()
supabase_service = SupabaseService()
strict_auth_required = StrictAuthRequired()

@router.get("/due-cards", response_model=DueCardsResponse, dependencies=[Depends(strict_auth_required)])
async def get_due_cards(
    request: Request,
    user_id: str = Depends(get_current_user),
    limit: int = Query(20, description="Maximum number of cards to return")
):
    """
    Get flashcards that are due for review based on spaced repetition algorithm.
    
    - **limit**: Maximum number of cards to return (default: 20)
    """
    try:
        if not user_id:
            raise AuthenticationError("Authentication required to access due cards")
        
        # Get due cards using Supabase function
        due_cards = supabase_service.get_due_cards(user_id, limit)
        
        return {
            'dueCards': due_cards,
            'count': len(due_cards)
        }
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error getting due cards: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/update-progress", status_code=status.HTTP_200_OK, dependencies=[Depends(strict_auth_required)])
async def update_card_progress(
    progress_request: CardProgressRequest,
    request: Request,
    user_id: str = Depends(get_current_user)
):
    """
    Update flashcard progress using SM-2 algorithm.
    
    - **cardId**: Unique identifier for the flashcard
    - **confidenceLevel**: User's confidence level (0-5)
    """
    try:
        if not user_id:
            raise AuthenticationError("Authentication required to update progress")
        
        # Validate confidence level (0-5)
        confidence_level = progress_request.confidenceLevel
        if confidence_level < 0 or confidence_level > 5:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Confidence level must be between 0 and 5"
            )
        
        # Update card progress using Supabase function
        result = supabase_service.update_card_progress(
            user_id=user_id,
            card_id=progress_request.cardId,
            confidence_level=confidence_level
        )
        
        return {"status": "success"}
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating card progress: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/stats", response_model=LearningStats, dependencies=[Depends(strict_auth_required)])
async def get_learning_stats(
    request: Request,
    user_id: str = Depends(get_current_user)
):
    """
    Get user learning statistics including cards learned, average confidence, and streak days.
    """
    try:
        if not user_id:
            raise AuthenticationError("Authentication required to access learning stats")
        
        if not supabase_service.is_connected():
            return {
                'error': 'Database not connected',
                'cardsLearned': 0,
                'averageConfidence': 0,
                'streakDays': 0
            }
        
        try:
            # Get cards learned count using our custom client
            cards_result = supabase_service.client.table("user_progress") \
                .select("id", count="exact") \
                .eq("user_id", user_id) \
                .execute()
            
            cards_learned = cards_result.count if hasattr(cards_result, 'count') else 0
            
            # Get average confidence
            confidence_result = supabase_service.client.table("user_progress") \
                .select("confidence_level") \
                .eq("user_id", user_id) \
                .execute()
            
            confidence_levels = [item.get('confidence_level', 0) for item in confidence_result.data] if confidence_result.data else []
            average_confidence = sum(confidence_levels) / len(confidence_levels) if confidence_levels else 0
            
            # Get study streak (simplified version)
            sessions_result = supabase_service.client.table("study_sessions") \
                .select("start_time") \
                .eq("user_id", user_id) \
                .order("start_time", desc=True) \
                .limit(30) \
                .execute()
            
            # Simple calculation - count unique days in the past week
            days = set()
            import datetime
            one_week_ago = datetime.datetime.now() - datetime.timedelta(days=7)
            
            for session in sessions_result.data:
                session_date = datetime.datetime.fromisoformat(session['start_time'].replace('Z', '+00:00'))
                if session_date > one_week_ago:
                    days.add(session_date.date())
            
            streak_days = len(days)
            
            return {
                'cardsLearned': cards_learned,
                'averageConfidence': round(average_confidence, 2),
                'streakDays': streak_days
            }
        except Exception as db_error:
            logger.error(f"Database error getting stats: {str(db_error)}")
            return {
                'error': str(db_error),
                'cardsLearned': 0,
                'averageConfidence': 0,
                'streakDays': 0
            }
            
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        logger.error(f"Error getting learning stats: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
