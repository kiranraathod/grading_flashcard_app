from functools import wraps
from flask import request, g
import logging
from ..services.auth_service import AuthService
from ..utils.error_handler import AuthenticationError

logger = logging.getLogger(__name__)
auth_service = AuthService()

def auth_required(f):
    """Middleware to check for valid authentication token"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get token from header
        auth_header = request.headers.get('Authorization')
        
        if not auth_header or not auth_header.startswith('Bearer '):
            logger.warning("Missing or invalid Authorization header")
            raise AuthenticationError("Authentication required", 401)
            
        token = auth_header.split(' ')[1]
        
        try:
            # Verify token
            payload = auth_service.verify_token(token)
            
            # Store user info in request context
            g.user_id = payload['sub']
            g.user_email = payload['email']
            
            return f(*args, **kwargs)
        except AuthenticationError as e:
            logger.warning(f"Authentication error: {str(e)}")
            raise e
            
    return decorated_function

def get_user_id():
    """Get user ID from request context"""
    return g.get('user_id')

def get_user_email():
    """Get user email from request context"""
    return g.get('user_email')
