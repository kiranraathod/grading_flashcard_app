from flask import Blueprint, request, jsonify
import logging
from ..services.postgres_service import PostgresService
from ..middleware.auth_middleware import auth_required, get_user_id
from ..utils.error_handler import AuthenticationError, ServiceError
from ..utils.db_helper import get_db_cursor

# Set up logger
logger = logging.getLogger(__name__)

profile_bp = Blueprint('profile', __name__)
db_service = PostgresService()

@profile_bp.route('/profile', methods=['GET'])
@auth_required
def get_profile():
    """Get user profile"""
    try:
        user_id = get_user_id()
        
        with get_db_cursor() as cursor:
            cursor.execute(
                """
                SELECT p.*, u.email
                FROM profiles p
                JOIN users u ON p.id = u.id
                WHERE p.id = %s
                """,
                (user_id,)
            )
            
            profile = cursor.fetchone()
            
            if not profile:
                return jsonify({'error': 'Profile not found'}), 404
            
            return jsonify(profile)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error getting profile: {str(e)}")
        return jsonify({'error': str(e)}), 500

@profile_bp.route('/profile', methods=['PUT'])
@auth_required
def update_profile():
    """Update user profile"""
    try:
        user_id = get_user_id()
        data = request.json
        
        # Build update fields
        update_fields = []
        params = []
        
        if 'display_name' in data:
            update_fields.append("display_name = %s")
            params.append(data['display_name'])
            
        if 'avatar_url' in data:
            update_fields.append("avatar_url = %s")
            params.append(data['avatar_url'])
        
        if not update_fields:
            return jsonify({'error': 'No fields to update'}), 400
        
        params.append(user_id)
        
        with get_db_cursor() as cursor:
            cursor.execute(
                f"""
                UPDATE profiles
                SET {", ".join(update_fields)}
                WHERE id = %s
                RETURNING *
                """,
                params
            )
            
            profile = cursor.fetchone()
            
            return jsonify(profile)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error updating profile: {str(e)}")
        return jsonify({'error': str(e)}), 500

@profile_bp.route('/profile/progress', methods=['POST'])
@auth_required
def update_progress():
    """Update user progress (XP and level)"""
    try:
        user_id = get_user_id()
        data = request.json
        
        if 'xp' not in data:
            return jsonify({'error': 'XP value is required'}), 400
        
        xp_to_add = int(data['xp'])
        
        with get_db_cursor() as cursor:
            # Get current progress
            cursor.execute(
                """
                SELECT level, xp, max_xp
                FROM profiles
                WHERE id = %s
                """,
                (user_id,)
            )
            
            result = cursor.fetchone()
            if not result:
                return jsonify({'error': 'Profile not found'}), 404
                
            level = result['level']
            current_xp = result['xp']
            max_xp = result['max_xp']
            
            # Calculate new progress
            new_xp = current_xp + xp_to_add
            new_level = level
            new_max_xp = max_xp
            
            # Level up if needed
            while new_xp >= new_max_xp:
                new_level += 1
                new_xp -= new_max_xp
                new_max_xp = int(new_max_xp * 1.2)  # Increase XP needed for next level
            
            # Update profile
            cursor.execute(
                """
                UPDATE profiles
                SET level = %s, xp = %s, max_xp = %s
                WHERE id = %s
                RETURNING level, xp, max_xp
                """,
                (new_level, new_xp, new_max_xp, user_id)
            )
            
            updated = cursor.fetchone()
            
            return jsonify({
                'level': updated['level'],
                'xp': updated['xp'],
                'max_xp': updated['max_xp'],
                'leveled_up': new_level > level
            })
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error updating progress: {str(e)}")
        return jsonify({'error': str(e)}), 500
