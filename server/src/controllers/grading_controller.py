"""
Controller for grading flashcard answers.
"""
import logging
import traceback
from typing import Dict, Any, List, Optional

from src.services.llm_service import LLMService
from src.utils.exceptions import LLMConnectionError, LLMResponseParsingError, InvalidInputError
from src.config.config import config

# Set up logger
logger = logging.getLogger(__name__)

class GradingController:
    """Controller for handling flashcard grading operations."""
    
    def __init__(self):
        """Initialize the grading controller with services."""
        self.llm_service = LLMService()
        self.feedback_store = {}  # Simple in-memory store for feedback (replace with DB in production)
        self.suggestion_cache = {}  # Cache for suggestions
    
    async def grade_answer(self, flashcard_id: str, question: str, user_answer: str, correct_answer: str) -> Dict[str, Any]:
        """
        Grade the user's answer to a flashcard question.
        
        Args:
            flashcard_id: The ID of the flashcard
            question: The flashcard question
            user_answer: The user's answer to grade
            correct_answer: The correct answer from the flashcard
            
        Returns:
            Dict containing grade, feedback, and suggestions
        """
        logger.debug(f"GradingController.grade_answer called with: flashcard_id={flashcard_id}, question={question}, user_answer={user_answer}, correct_answer={correct_answer}")
        
        # Validate inputs
        if not flashcard_id or not flashcard_id.strip():
            logger.error("Missing flashcard_id")
            return self._create_error_response("Missing flashcard ID", error_type="validation_error")
            
        if not question or not question.strip():
            logger.error("Missing question")
            return self._create_error_response("Missing question", error_type="validation_error")
            
        if not correct_answer or not correct_answer.strip():
            logger.error("Missing correct_answer")
            return self._create_error_response("Missing correct answer", error_type="validation_error")
        
        try:
            logger.debug("Calling LLM service grade_answer method...")
            result = await self.llm_service.grade_answer(question, user_answer, correct_answer)
            logger.debug(f"LLM service returned result: {result}")
            
            # Cache the suggestions for this flashcard
            if 'suggestions' in result and result['suggestions']:
                self.suggestion_cache[flashcard_id] = result['suggestions']
                
            return result
        except LLMConnectionError as llm_error:
            logger.error(f"LLM connection error in GradingController.grade_answer: {str(llm_error)}")
            
            # Return a clear error message about LLM connection
            return self._create_error_response(
                f"LLM Service Error: {str(llm_error)}", 
                error_type="llm_connection_error"
            )
        except LLMResponseParsingError as parsing_error:
            logger.error(f"LLM response parsing error: {str(parsing_error)}")
            
            return self._create_error_response(
                f"Error parsing LLM response: {str(parsing_error)}", 
                error_type="llm_response_error"
            )
        except Exception as e:
            logger.error(f"Unexpected error in GradingController.grade_answer: {str(e)}")
            logger.error(traceback.format_exc())
            
            # Create a default response to maintain stability
            return self._create_error_response(
                f"Unexpected error: {str(e)}", 
                error_type="system_error"
            )
    
    def _create_error_response(self, message: str, error_type: str = "system_error") -> Dict[str, Any]:
        """
        Create a standardized error response.
        
        Args:
            message: Error message
            error_type: Type of error
            
        Returns:
            Standard error response
        """
        logger.warning(f"⚠️ Returning error response: {error_type} - {message}")
        
        error_responses = {
            "llm_connection_error": {
                'grade': 'X',  # Use 'X' to indicate system error
                'feedback': f'LLM Service Error: {message}',
                'suggestions': [
                    'The AI grading service is currently unavailable',
                    'Please try again later or contact system administrator',
                    'Verify your internet connection and API credentials'
                ],
                'error': error_type
            },
            "llm_response_error": {
                'grade': 'X',
                'feedback': f'Error processing your answer: {message}',
                'suggestions': [
                    'Please try a different wording in your answer',
                    'If this error persists, contact support'
                ],
                'error': error_type
            },
            "validation_error": {
                'grade': 'X',
                'feedback': f'Input validation error: {message}',
                'suggestions': [
                    'Please ensure all required fields are provided',
                    'Check your input format and try again'
                ],
                'error': error_type
            },
            "system_error": {
                'grade': 'X',
                'feedback': f'System error: {message}',
                'suggestions': [
                    'Please try again with a different answer',
                    'If this error persists, contact support'
                ],
                'error': error_type
            }
        }
        
        # Get the appropriate error response or default to system_error
        return error_responses.get(error_type, error_responses["system_error"])
    
    async def get_suggestions(self, flashcard_id: str) -> Dict[str, Any]:
        """
        Get improvement suggestions for a specific flashcard.
        
        Args:
            flashcard_id: The ID of the flashcard
            
        Returns:
            Dict containing flashcardId and suggestions
        """
        logger.debug(f"Getting suggestions for flashcard_id={flashcard_id}")
        
        # Validate input
        if not flashcard_id or not flashcard_id.strip():
            logger.error("Missing flashcard_id")
            raise InvalidInputError("flashcardId cannot be empty")
            
        # Get cached suggestions or provide defaults
        if flashcard_id in self.suggestion_cache:
            suggestions = self.suggestion_cache[flashcard_id]
            logger.debug(f"Using cached suggestions: {suggestions}")
        else:
            # If no cached suggestions, provide generic ones
            suggestions = [
                "Try to be more specific in your answer",
                "Review the key concepts related to this topic",
                "Practice recalling this information regularly"
            ]
            logger.debug(f"Using default suggestions: {suggestions}")
            
        return {
            'flashcardId': flashcard_id,
            'suggestions': suggestions
        }
    
    async def submit_feedback(self, flashcard_id: str, user_feedback: str) -> bool:
        """
        Store user feedback on the grading process.
        
        Args:
            flashcard_id: The ID of the flashcard
            user_feedback: The user's feedback
            
        Returns:
            True if feedback was stored successfully
            
        Raises:
            InvalidInputError: If inputs are invalid
        """
        # Validate inputs
        if not flashcard_id or not flashcard_id.strip():
            logger.error("Missing flashcard_id in submit_feedback")
            raise InvalidInputError("flashcardId cannot be empty")
            
        if not user_feedback or not user_feedback.strip():
            logger.error("Missing user_feedback in submit_feedback")
            raise InvalidInputError("userFeedback cannot be empty")
        
        # In a real application, this would be stored in a database
        logger.debug(f"Storing feedback for flashcard_id={flashcard_id}: {user_feedback}")
        self.feedback_store[flashcard_id] = user_feedback
        return True
