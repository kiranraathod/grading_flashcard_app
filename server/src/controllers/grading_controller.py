from src.services.llm_service import LLMService
from src.services.supabase_service import SupabaseService
from src.middleware.auth_middleware import get_user_id
from flask import g
import logging
import traceback

# Set up logger
logger = logging.getLogger(__name__)

class GradingController:
    def __init__(self):
        self.llm_service = LLMService()
        self.supabase_service = SupabaseService()
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
            
            # Save grade to Supabase if user is authenticated
            user_id = get_user_id()
            if user_id:
                logger.debug(f"Saving grade for user {user_id}")
                self.supabase_service.save_grade(
                    user_id=user_id,
                    flashcard_id=flashcard_id,
                    user_answer=user_answer,
                    grade=result['grade'],
                    feedback=result['feedback'],
                    suggestions=result['suggestions']
                )
                
                # Update spaced repetition data based on grade
                confidence_level = self._convert_grade_to_confidence(result['grade'])
                self.supabase_service.update_card_progress(
                    user_id=user_id,
                    card_id=flashcard_id,
                    confidence_level=confidence_level
                )
                
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
        
        # First check if we have specific cached suggestions for this card
        if flashcard_id in self.suggestion_cache:
            suggestions = self.suggestion_cache[flashcard_id]
            logger.debug(f"Using cached suggestions: {suggestions}")
        else:
            # Check if we have historical grading data for this card in Supabase
            user_id = get_user_id()
            if user_id:
                user_progress = self.supabase_service.get_user_progress(user_id, flashcard_id)
                if user_progress and user_progress.get('confidence_level', 0) < 3:
                    # Generate personalized suggestions based on past performance
                    suggestions = [
                        "Review your previous attempts with this card",
                        "Focus on understanding the key concepts",
                        "Try a different approach to remember this information"
                    ]
                    logger.debug(f"Using personalized suggestions based on progress: {suggestions}")
                    return {
                        'flashcardId': flashcard_id,
                        'suggestions': suggestions
                    }
            
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
        logger.debug(f"Storing feedback for flashcard_id={flashcard_id}: {user_feedback}")
        
        # Save to Supabase if user is authenticated
        user_id = get_user_id()
        if user_id:
            self.supabase_service.save_feedback(
                user_id=user_id,
                flashcard_id=flashcard_id,
                feedback=user_feedback
            )
        
        return True
    
    def _convert_grade_to_confidence(self, grade):
        """Convert letter grade to confidence level (0-5) for spaced repetition"""
        grade_to_confidence = {
            'A': 5,  # Perfect recall
            'B': 4,  # Good recall with minor errors
            'C': 3,  # Acceptable recall with some errors
            'D': 2,  # Poor recall with major errors
            'F': 1,  # Failed recall
            'N/A': 0  # Error or not graded
        }
        return grade_to_confidence.get(grade, 0)
