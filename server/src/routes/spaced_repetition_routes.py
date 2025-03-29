from flask import Blueprint, request, jsonify, g
from ..services.postgres_service import PostgresService
from ..middleware.auth_middleware import auth_required, get_user_id
from ..utils.error_handler import AuthenticationError
import logging

# Set up logger
logger = logging.getLogger(__name__)

spaced_bp = Blueprint('spaced_repetition', __name__)
db_service = PostgresService()

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
        
        # Get due cards using PostgreSQL function
        due_cards = db_service.get_due_cards(user_id, limit)
        
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
        
        # Update card progress using PostgreSQL function
        result = db_service.update_card_progress(
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
        
        # Get stats from PostgreSQL service
        stats = db_service.get_learning_stats(user_id)
        
        return jsonify(stats)
    except AuthenticationError as e:
        logger.warning(f"Authentication error: {str(e)}")
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error getting learning stats: {str(e)}")
        return jsonify({
            'error': str(e),
            'cardsLearned': 0,
            'averageConfidence': 0,
            'streakDays': 0
        }), 500
