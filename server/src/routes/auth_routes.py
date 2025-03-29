from flask import Blueprint, request, jsonify
import logging
from ..services.auth_service import AuthService
from ..utils.error_handler import AuthenticationError, ServiceError

logger = logging.getLogger(__name__)
auth_bp = Blueprint('auth', __name__)
auth_service = AuthService()

@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user"""
    try:
        data = request.json
        
        if not all(key in data for key in ['email', 'password']):
            return jsonify({'error': 'Missing email or password'}), 400
            
        result = auth_service.register(data['email'], data['password'])
        
        return jsonify(result)
    except ServiceError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error during registration: {str(e)}")
        return jsonify({'error': 'Registration failed'}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """Login a user"""
    try:
        data = request.json
        
        if not all(key in data for key in ['email', 'password']):
            return jsonify({'error': 'Missing email or password'}), 400
            
        result = auth_service.login(data['email'], data['password'])
        
        return jsonify(result)
    except AuthenticationError as e:
        return jsonify({'error': str(e)}), e.status_code
    except Exception as e:
        logger.error(f"Error during login: {str(e)}")
        return jsonify({'error': 'Login failed'}), 500

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    """Reset user password (placeholder - would send email in production)"""
    try:
        data = request.json
        
        if 'email' not in data:
            return jsonify({'error': 'Missing email'}), 400
            
        # In a real implementation, this would send a password reset email
        # For this example, we'll just acknowledge the request
        
        return jsonify({'message': 'Password reset instructions sent'})
    except Exception as e:
        logger.error(f"Error during password reset: {str(e)}")
        return jsonify({'error': 'Password reset failed'}), 500
