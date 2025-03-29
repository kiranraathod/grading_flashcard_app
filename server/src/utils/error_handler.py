class ServiceError(Exception):
    """Base class for service errors"""
    
    def __init__(self, message, status_code=500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)
        
class AuthenticationError(ServiceError):
    """Authentication related errors"""
    
    def __init__(self, message, status_code=401):
        super().__init__(message, status_code)
        
class ValidationError(ServiceError):
    """Data validation errors"""
    
    def __init__(self, message, status_code=400):
        super().__init__(message, status_code)
        
class NotFoundError(ServiceError):
    """Resource not found errors"""
    
    def __init__(self, message, status_code=404):
        super().__init__(message, status_code)

class AuthorizationError(ServiceError):
    """Authorization related errors"""
    
    def __init__(self, message, status_code=403):
        super().__init__(message, status_code)
