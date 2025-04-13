"""
Custom exception classes for the application.
"""

class BaseFlashcardAPIError(Exception):
    """Base exception class for Flashcard API errors"""
    def __init__(self, message, status_code=500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class LLMConnectionError(BaseFlashcardAPIError):
    """Raised when connection to LLM service fails"""
    def __init__(self, message="Failed to connect to LLM service", status_code=503):
        super().__init__(message, status_code)


class LLMResponseParsingError(BaseFlashcardAPIError):
    """Raised when parsing LLM response fails"""
    def __init__(self, message="Failed to parse LLM response", status_code=500):
        super().__init__(message, status_code)


class InvalidInputError(BaseFlashcardAPIError):
    """Raised when input validation fails"""
    def __init__(self, message="Invalid input provided", status_code=400):
        super().__init__(message, status_code)


class ResourceNotFoundError(BaseFlashcardAPIError):
    """Raised when a requested resource is not found"""
    def __init__(self, message="Resource not found", status_code=404):
        super().__init__(message, status_code)
