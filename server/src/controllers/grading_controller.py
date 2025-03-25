from src.services.llm_service import LLMService
import logging

# Set up logger
logger = logging.getLogger(__name__)

class GradingController:
    def __init__(self):
        self.llm_service = LLMService()
        self.feedback_store = {}  # Simple in-memory store for feedback
        self.suggestion_cache = {}  # Cache for suggestions
    
    async def grade_answer(self, flashcard_id, question, user_answer):
        """Grade the user's answer to a flashcard question"""
        logger.info(f"GradingController.grade_answer called with: flashcard_id={flashcard_id}, question={question}, user_answer={user_answer}")
        
        try:
            logger.info("Calling LLM service grade_answer method...")
            result = await self.llm_service.grade_answer(question, user_answer)
            logger.info(f"LLM service returned result: {result}")
            
            # Cache the suggestions for this flashcard
            if 'suggestions' in result and result['suggestions']:
                self.suggestion_cache[flashcard_id] = result['suggestions']
                
            return result
        except Exception as e:
            import traceback
            logger.error(f"Error in GradingController.grade_answer: {str(e)}")
            logger.error(traceback.format_exc())
            raise
    
    async def get_suggestions(self, flashcard_id):
        """Get improvement suggestions for a specific flashcard"""
        if flashcard_id in self.suggestion_cache:
            suggestions = self.suggestion_cache[flashcard_id]
        else:
            # If no cached suggestions, provide generic ones
            suggestions = [
                "Try to be more specific in your answer",
                "Review the key concepts related to this topic",
                "Practice recalling this information regularly"
            ]
            
        return {
            'flashcardId': flashcard_id,
            'suggestions': suggestions
        }
    
    async def submit_feedback(self, flashcard_id, user_feedback):
        """Store user feedback on the grading process"""
        # In a real application, this would be stored in a database
        self.feedback_store[flashcard_id] = user_feedback
        return True