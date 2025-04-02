class AuthenticationError(Exception):
    """Exception raised for authentication errors."""
    def __init__(self, message="Authentication error", status_code=401):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class ServiceError(Exception):
    """Exception raised for service errors."""
    def __init__(self, message="Service error", status_code=500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class RequestValidationError(Exception):
    """Exception raised for request validation errors."""
    def __init__(self, message="Invalid request", status_code=400):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class NotFoundError(Exception):
    """Exception raised for not found resources."""
    def __init__(self, message="Resource not found", status_code=404):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class DatabaseError(Exception):
    """Exception raised for database errors."""
    def __init__(self, message="Database error", status_code=500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)
