from src.services.llm_service import LLMService
import logging
import traceback

# Set up logger
logger = logging.getLogger(__name__)

class GradingController:
    def __init__(self):
        self.llm_service = LLMService()
        self.feedback_store = {}  # Simple in-memory store for feedback
        self.suggestion_cache = {}  # Cache for suggestions
    
    async def grade_answer(self, flashcard_id, question, user_answer):
        """Grade the user's answer to a flashcard question"""
        logger.debug(f"GradingController.grade_answer called with: flashcard_id={flashcard_id}, question={question}, user_answer={user_answer}")
        
        try:
            logger.debug("Calling LLM service grade_answer method...")
            result = await self.llm_service.grade_answer(question, user_answer)
            logger.debug(f"LLM service returned result: {result}")
            
            # Cache the suggestions for this flashcard
            if 'suggestions' in result and result['suggestions']:
                self.suggestion_cache[flashcard_id] = result['suggestions']
                
            return result
        except Exception as e:
            logger.error(f"Error in GradingController.grade_answer: {str(e)}")
            logger.error(traceback.format_exc())
            
            # Create a default response to maintain stability
            logger.warning("⚠️ Returning emergency default grade due to error!")
            default_response = {
                'grade': 'F',  # Default to F instead of B for safety
                'feedback': f'Error grading answer. The system encountered an issue processing your response: {str(e)}',
                'suggestions': [
                    'Please try again with a different answer',
                    'If this error persists, contact support'
                ]
            }
            return default_response
    
    async def get_suggestions(self, flashcard_id):
        """Get improvement suggestions for a specific flashcard"""
        logger.debug(f"Getting suggestions for flashcard_id={flashcard_id}")
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
    
    async def submit_feedback(self, flashcard_id, user_feedback):
        """Store user feedback on the grading process"""
        # In a real application, this would be stored in a database
        logger.debug(f"Storing feedback for flashcard_id={flashcard_id}: {user_feedback}")
        self.feedback_store[flashcard_id] = user_feedback
        return True
