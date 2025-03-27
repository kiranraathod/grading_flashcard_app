from flask import Blueprint, request, jsonify, g
from src.services.supabase_service import SupabaseService
from src.middleware.auth_middleware import auth_required, get_user_id
from src.utils.error_handler import AuthenticationError
import logging

# Set up logger
logger = logging.getLogger(__name__)

spaced_bp = Blueprint('spaced_repetition', __name__)
supabase_service = SupabaseService()

@spaced_bp.route('/due-cards', methods=['GET'])
@auth_required
def get_due_cards():
    """Get flashcards that are due for review based on spaced repetition algorithm"""
    try:
        # Authentication required for this endpoint
        user_id = get_user_id()
        if not user_id:
            raise AuthenticationError("Authentication required to access due cards")
        
        limit = request.args.get('limit', default=20, type=int)
        
        # Get due cards using Supabase function
        due_cards = supabase_service.get_due_cards(user_id, limit)
        
        return jsonify({
            'dueCards': due_cards,
            'count': len(due_cards)
        })
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error getting due cards: {str(e)}")
        return jsonify({'error': str(e)}), 500

@spaced_bp.route('/update-progress', methods=['POST'])
@auth_required
def update_card_progress():
    """Update flashcard progress using SM-2 algorithm"""
    try:
        # Authentication required for this endpoint
        user_id = get_user_id()
        if not user_id:
            raise AuthenticationError("Authentication required to update progress")
        
        data = request.json
        
        if not all(key in data for key in ['cardId', 'confidenceLevel']):
            logger.error("Missing required fields in request")
            return jsonify({'error': 'Missing required fields'}), 400
        
        card_id = data['cardId']
        confidence_level = data['confidenceLevel']
        
        # Validate confidence level (0-5)
        if not isinstance(confidence_level, int) or confidence_level < 0 or confidence_level > 5:
            return jsonify({'error': 'Confidence level must be an integer between 0 and 5'}), 400
        
        # Update card progress using Supabase function
        result = supabase_service.update_card_progress(
            user_id=user_id,
            card_id=card_id,
            confidence_level=confidence_level
        )
        
        return jsonify({'status': 'success'})
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error updating card progress: {str(e)}")
        return jsonify({'error': str(e)}), 500

@spaced_bp.route('/stats', methods=['GET'])
@auth_required
def get_learning_stats():
    """Get user learning statistics"""
    try:
        # Authentication required for this endpoint
        user_id = get_user_id()
        if not user_id:
            raise AuthenticationError("Authentication required to access learning stats")
        
        if not supabase_service.is_connected():
            return jsonify({
                'error': 'Database not connected',
                'cardsLearned': 0,
                'averageConfidence': 0,
                'streakDays': 0
            }), 503
        
        try:
            # Get cards learned count
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
            
            return jsonify({
                'cardsLearned': cards_learned,
                'averageConfidence': round(average_confidence, 2),
                'streakDays': streak_days
            })
        except Exception as db_error:
            logger.error(f"Database error getting stats: {str(db_error)}")
            return jsonify({
                'error': str(db_error),
                'cardsLearned': 0,
                'averageConfidence': 0,
                'streakDays': 0
            }), 500
            
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error getting learning stats: {str(e)}")
        return jsonify({'error': str(e)}), 500
