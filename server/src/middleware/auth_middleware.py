import logging
from functools import wraps
from flask import request, g, jsonify
from ..services.supabase_service import SupabaseService

logger = logging.getLogger(__name__)
supabase_service = SupabaseService()

def auth_required(f):
    """Middleware to verify authentication token"""
    @wraps(f)
    def decorated(*args, **kwargs):
        # Get token from header
        auth_header = request.headers.get('Authorization')
        
        if not auth_header or not auth_header.startswith('Bearer '):
            logger.warning("No valid Authorization header found")
            # Continue but with no user attached
            g.user_id = None
            return f(*args, **kwargs)
        
        token = auth_header.split(' ')[1]
        
        if not token:
            logger.warning("Empty token provided")
            g.user_id = None
            return f(*args, **kwargs)
        
        # Verify token
        payload = supabase_service.verify_token(token)
        
        if not payload:
            logger.warning("Invalid token")
            g.user_id = None
            return f(*args, **kwargs)
        
        # Set user ID in Flask's global context
        g.user_id = payload.get('sub')
        logger.debug(f"Authenticated user: {g.user_id}")
        
        return f(*args, **kwargs)
    
    return decorated

def get_user_id():
    """Helper function to get the current user ID from the request context"""
    # First check if user_id is set by auth middleware
    if hasattr(g, 'user_id') and g.user_id:
        return g.user_id
    
    # Then check if it's in the request body (for backward compatibility)
    if request.is_json and request.json and 'userId' in request.json:
        return request.json.get('userId')
    
    return None
