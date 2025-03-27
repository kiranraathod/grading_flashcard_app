import os
import logging
from supabase import create_client, Client
from jose import jwt
from ..utils.error_handler import ServiceError

logger = logging.getLogger(__name__)

class SupabaseService:
    """Service class for Supabase interactions"""
    
    def __init__(self):
        self.url = os.getenv("SUPABASE_URL")
        self.key = os.getenv("SUPABASE_KEY")
        self.jwt_secret = os.getenv("SUPABASE_JWT_SECRET")
        
        if not self.url or not self.key:
            logger.warning("Supabase URL or key not set, some features may not work")
            self.client = None
        else:
            try:
                self.client = create_client(self.url, self.key)
                logger.info(f"Supabase client initialized with URL: {self.url}")
            except Exception as e:
                logger.error(f"Error initializing Supabase client: {str(e)}")
                self.client = None
    
    def is_connected(self):
        """Check if Supabase client is connected"""
        return self.client is not None
    
    def verify_token(self, token):
        """Verify a Supabase JWT token"""
        if not self.jwt_secret:
            logger.warning("JWT secret not set, token verification skipped")
            return None
        
        try:
            payload = jwt.decode(
                token, 
                self.jwt_secret, 
                algorithms=["HS256"],
                options={"verify_signature": True}
            )
            return payload
        except Exception as e:
            logger.error(f"Error verifying token: {str(e)}")
            return None
    
    def save_grade(self, user_id, flashcard_id, user_answer, grade, feedback, suggestions):
        """Save a grade result to Supabase"""
        if not self.is_connected():
            logger.warning("Supabase not connected, skipping grade saving")
            return
        
        try:
            result = self.client.table("flashcard_grades").insert({
                "user_id": user_id,
                "card_id": flashcard_id,
                "user_answer": user_answer,
                "grade": grade,
                "feedback": feedback,
                "suggestions": suggestions
            }).execute()
            
            return result.data
        except Exception as e:
            logger.error(f"Error saving grade to Supabase: {str(e)}")
            # Non-critical error, don't raise exception
            return None
    
    def save_feedback(self, user_id, flashcard_id, feedback):
        """Save user feedback to Supabase"""
        if not self.is_connected():
            logger.warning("Supabase not connected, skipping feedback saving")
            return
        
        try:
            result = self.client.table("user_feedback").insert({
                "user_id": user_id,
                "card_id": flashcard_id,
                "feedback": feedback
            }).execute()
            
            return result.data
        except Exception as e:
            logger.error(f"Error saving feedback to Supabase: {str(e)}")
            # Non-critical error, don't raise exception
            return None
    
    def get_user_progress(self, user_id, card_id):
        """Get user progress for a specific flashcard"""
        if not self.is_connected():
            logger.warning("Supabase not connected, skipping progress retrieval")
            return None
        
        try:
            result = self.client.table("user_progress").select("*").eq("user_id", user_id).eq("card_id", card_id).execute()
            
            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error getting user progress from Supabase: {str(e)}")
            return None
    
    def update_card_progress(self, user_id, card_id, confidence_level):
        """Update card progress using the SM-2 algorithm"""
        if not self.is_connected():
            logger.warning("Supabase not connected, skipping progress update")
            return
        
        try:
            # Call the SQL function we created
            result = self.client.rpc(
                "update_card_progress", 
                {
                    "p_user_id": user_id,
                    "p_card_id": card_id,
                    "p_confidence": confidence_level
                }
            ).execute()
            
            return result.data
        except Exception as e:
            logger.error(f"Error updating card progress in Supabase: {str(e)}")
            return None
    
    def get_due_cards(self, user_id, limit=20):
        """Get cards due for review for a user"""
        if not self.is_connected():
            logger.warning("Supabase not connected, skipping due cards retrieval")
            return []
        
        try:
            # Call the SQL function we created
            result = self.client.rpc(
                "get_due_cards", 
                {
                    "user_uuid": user_id
                }
            ).execute()
            
            return result.data or []
        except Exception as e:
            logger.error(f"Error getting due cards from Supabase: {str(e)}")
            return []
