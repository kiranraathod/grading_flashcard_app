class ServiceError(Exception):
    """Base exception class for service errors"""
    
    def __init__(self, message, status_code=500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class AuthenticationError(ServiceError):
    """Raised when authentication fails"""
    
    def __init__(self, message="Authentication failed"):
        super().__init__(message, 401)

class AuthorizationError(ServiceError):
    """Raised when user doesn't have permission"""
    
    def __init__(self, message="Not authorized"):
        super().__init__(message, 403)

class ValidationError(ServiceError):
    """Raised when input validation fails"""
    
    def __init__(self, message="Invalid input"):
        super().__init__(message, 400)

class ResourceNotFoundError(ServiceError):
    """Raised when requested resource is not found"""
    
    def __init__(self, message="Resource not found"):
        super().__init__(message, 404)
