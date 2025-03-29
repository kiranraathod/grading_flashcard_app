from flask import Blueprint, request, jsonify
import logging
from ..services.postgres_service import PostgresService
from ..middleware.auth_middleware import auth_required, get_user_id
from ..utils.error_handler import AuthenticationError, NotFoundError, ServiceError, AuthorizationError

# Set up logger
logger = logging.getLogger(__name__)

flashcard_bp = Blueprint('flashcards', __name__)
db_service = PostgresService()

@flashcard_bp.route('/flashcard-sets', methods=['GET'])
def get_flashcard_sets():
    """Get all flashcard sets (public or owned by the user)"""
    try:
        # Check if user is authenticated
        user_id = get_user_id() if request.headers.get('Authorization') else None
        
        # Get sets from PostgreSQL service
        sets = db_service.get_flashcard_sets(user_id)
        
        return jsonify({
            'sets': sets,
            'count': len(sets)
        })
    except Exception as e:
        logger.error(f"Error getting flashcard sets: {str(e)}")
        return jsonify({'error': str(e)}), 500

@flashcard_bp.route('/flashcard-sets/<set_id>', methods=['GET'])
def get_flashcard_set(set_id):
    """Get a specific flashcard set"""
    try:
        # Check if user is authenticated
        user_id = get_user_id() if request.headers.get('Authorization') else None
        
        # Get set from PostgreSQL service
        set_data = db_service.get_flashcard_set(set_id, user_id)
        
        return jsonify(set_data)
    except NotFoundError as e:
        return jsonify({'error': str(e)}), 404
    except Exception as e:
        logger.error(f"Error getting flashcard set: {str(e)}")
        return jsonify({'error': str(e)}), 500

@flashcard_bp.route('/flashcard-sets', methods=['POST'])
@auth_required
def create_flashcard_set():
    """Create a new flashcard set"""
    try:
        user_id = get_user_id()
        data = request.json
        
        if 'title' not in data:
            return jsonify({'error': 'Title is required'}), 400
        
        # Create set using PostgreSQL service
        set_data = db_service.create_flashcard_set(user_id, data)
        
        return jsonify(set_data)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except ServiceError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error creating flashcard set: {str(e)}")
        return jsonify({'error': str(e)}), 500

@flashcard_bp.route('/flashcard-sets/<set_id>', methods=['PUT'])
@auth_required
def update_flashcard_set(set_id):
    """Update a flashcard set"""
    try:
        user_id = get_user_id()
        data = request.json
        
        if 'title' not in data:
            return jsonify({'error': 'Title is required'}), 400
        
        # Update set using PostgreSQL service
        set_data = db_service.update_flashcard_set(set_id, user_id, data)
        
        return jsonify(set_data)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except AuthorizationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except ServiceError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error updating flashcard set: {str(e)}")
        return jsonify({'error': str(e)}), 500

@flashcard_bp.route('/flashcard-sets/<set_id>', methods=['DELETE'])
@auth_required
def delete_flashcard_set(set_id):
    """Delete a flashcard set"""
    try:
        user_id = get_user_id()
        
        # Delete set using PostgreSQL service
        result = db_service.delete_flashcard_set(set_id, user_id)
        
        return jsonify(result)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except AuthorizationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except ServiceError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error deleting flashcard set: {str(e)}")
        return jsonify({'error': str(e)}), 500

@flashcard_bp.route('/flashcard-sets/<set_id>/rate', methods=['POST'])
@auth_required
def rate_flashcard_set(set_id):
    """Rate a flashcard set"""
    try:
        user_id = get_user_id()
        data = request.json
        
        if 'rating' not in data:
            return jsonify({'error': 'Rating is required'}), 400
        
        rating = float(data['rating'])
        if rating < 0 or rating > 5:
            return jsonify({'error': 'Rating must be between 0 and 5'}), 400
        
        # Rate set using PostgreSQL service
        result = db_service.rate_flashcard_set(set_id, user_id, rating)
        
        return jsonify(result)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except NotFoundError as e:
        return jsonify({'error': str(e)}), 404
    except ServiceError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error rating flashcard set: {str(e)}")
        return jsonify({'error': str(e)}), 500
