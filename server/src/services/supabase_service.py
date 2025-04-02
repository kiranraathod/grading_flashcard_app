import os
import logging
import traceback
from jose import jwt
from .custom_supabase import create_custom_client
from ..utils.error_handler import ServiceError

logger = logging.getLogger(__name__)

class SupabaseService:
    """
    Service class for Supabase interactions
    """
    
    def __init__(self):
        self.url = os.getenv("SUPABASE_URL")
        self.key = os.getenv("SUPABASE_KEY")
        self.jwt_secret = os.getenv("SUPABASE_JWT_SECRET")
        
        try:
            if self.url and self.key:
                # Use our custom Supabase client implementation that avoids compatibility issues
                self.client = create_custom_client(self.url, self.key)
                logger.info("Custom Supabase client initialized successfully")
            else:
                logger.warning("Supabase URL or key not provided, using mock implementation")
                self._initialize_mock_storage()
                self.client = None
        except Exception as e:
            logger.error(f"Failed to initialize Supabase client: {str(e)}")
            logger.error(traceback.format_exc())
            self._initialize_mock_storage()
            self.client = None
    
    def _initialize_mock_storage(self):
        """Initialize mock storage for development/testing"""
        logger.info("Initializing mock storage")
        self._storage = {
            "flashcard_grades": [],
            "user_feedback": [],
            "user_progress": [],
            "study_sessions": []
        }
    
    def is_connected(self):
        """Check if Supabase client is connected"""
        return self.client is not None
    
    def verify_token(self, token):
        """Verify a Supabase JWT token"""
        if not token:
            logger.warning("No token provided for verification")
            return None
            
        try:
            if self.client:
                # Use custom client auth verification
                response = self.client.auth_get_user(token)
                if response and response.get("id"):
                    user_id = response.get("id")
                    logger.debug(f"Token verified for user: {user_id}")
                    return {"sub": user_id}
                return None
            elif self.jwt_secret:
                # Fallback to manual JWT verification
                logger.debug("Using manual JWT verification")
                payload = jwt.decode(
                    token, 
                    self.jwt_secret, 
                    algorithms=["HS256"],
                    options={"verify_signature": True}
                )
                return payload
            else:
                logger.warning("No JWT secret configured, token verification skipped")
                return None
        except Exception as e:
            logger.error(f"Error verifying token: {str(e)}")
            logger.error(traceback.format_exc())
            return None
    
    def save_grade(self, user_id, flashcard_id, user_answer, grade, feedback, suggestions):
        """Save a grade result to storage"""
        logger.info(f"Saving grade for user {user_id}, card {flashcard_id}")
        
        try:
            if self.client:
                # Use actual Supabase client
                result = self.client.table("flashcard_grades").insert({
                    "user_id": user_id,
                    "card_id": flashcard_id,
                    "user_answer": user_answer,
                    "grade": grade,
                    "feedback": feedback,
                    "suggestions": suggestions
                }).execute()
                
                return result.data
            else:
                # Use mock storage
                grade_record = {
                    "id": f"grade_{len(self._storage['flashcard_grades']) + 1}",
                    "user_id": user_id,
                    "card_id": flashcard_id,
                    "user_answer": user_answer,
                    "grade": grade,
                    "feedback": feedback,
                    "suggestions": suggestions,
                    "created_at": "2023-01-01T00:00:00Z"  # Mock timestamp
                }
                
                self._storage["flashcard_grades"].append(grade_record)
                return [grade_record]
        except Exception as e:
            logger.error(f"Error saving grade: {str(e)}")
            logger.error(traceback.format_exc())
            raise ServiceError(f"Failed to save grade: {str(e)}")
    
    def save_feedback(self, user_id, flashcard_id, feedback):
        """Save user feedback to storage"""
        logger.info(f"Saving feedback for user {user_id}, card {flashcard_id}")
        
        try:
            if self.client:
                # Use actual Supabase client
                result = self.client.table("user_feedback").insert({
                    "user_id": user_id,
                    "card_id": flashcard_id,
                    "feedback": feedback
                }).execute()
                
                return result.data
            else:
                # Use mock storage
                feedback_record = {
                    "id": f"feedback_{len(self._storage['user_feedback']) + 1}",
                    "user_id": user_id,
                    "card_id": flashcard_id,
                    "feedback": feedback,
                    "created_at": "2023-01-01T00:00:00Z"  # Mock timestamp
                }
                
                self._storage["user_feedback"].append(feedback_record)
                return [feedback_record]
        except Exception as e:
            logger.error(f"Error saving feedback: {str(e)}")
            logger.error(traceback.format_exc())
            raise ServiceError(f"Failed to save feedback: {str(e)}")
    
    def get_user_progress(self, user_id, card_id):
        """Get user progress for a specific flashcard"""
        logger.info(f"Getting progress for user {user_id}, card {card_id}")
        
        try:
            if self.client:
                # Use actual Supabase client
                result = self.client.table("user_progress") \
                    .select("*") \
                    .eq("user_id", user_id) \
                    .eq("card_id", card_id) \
                    .execute()
                
                if result.data and len(result.data) > 0:
                    return result.data[0]
                
                # No progress found, create a new one
                import datetime
                new_progress = {
                    "user_id": user_id,
                    "card_id": card_id,
                    "confidence_level": 0,
                    "ease_factor": 2.5,
                    "interval": 1,
                    "repetitions": 0,
                    "next_review_date": datetime.datetime.now().isoformat()
                }
                
                insert_result = self.client.table("user_progress").insert(new_progress).execute()
                return insert_result.data[0] if insert_result.data else None
            else:
                # Find matching progress in mock storage
                for progress in self._storage["user_progress"]:
                    if progress["user_id"] == user_id and progress["card_id"] == card_id:
                        return progress
                
                # No progress found, create a new one
                new_progress = {
                    "id": f"progress_{len(self._storage['user_progress']) + 1}",
                    "user_id": user_id,
                    "card_id": card_id,
                    "confidence_level": 0,
                    "ease_factor": 2.5,
                    "interval": 1,
                    "repetitions": 0,
                    "next_review_date": "2023-01-01T00:00:00Z",  # Mock timestamp
                    "created_at": "2023-01-01T00:00:00Z"  # Mock timestamp
                }
                
                self._storage["user_progress"].append(new_progress)
                return new_progress
        except Exception as e:
            logger.error(f"Error getting user progress: {str(e)}")
            logger.error(traceback.format_exc())
            raise ServiceError(f"Failed to get user progress: {str(e)}")
    
    def update_card_progress(self, user_id, card_id, confidence_level):
        """Update card progress using the SM-2 algorithm"""
        logger.info(f"Updating progress for user {user_id}, card {card_id}, confidence {confidence_level}")
        
        try:
            # Get existing progress
            progress = self.get_user_progress(user_id, card_id)
            
            if not progress:
                raise ServiceError("Failed to get progress for update")
            
            # Calculate new values based on SM-2 algorithm
            repetitions = progress["repetitions"] + 1
            old_ease = progress["ease_factor"]
            
            # Update ease factor based on confidence
            if confidence_level >= 3:
                ease_factor = max(1.3, old_ease + (0.1 - (5 - confidence_level) * 0.08))
                interval = int(progress["interval"] * ease_factor)
            else:
                ease_factor = max(1.3, old_ease - 0.2)
                interval = 1
            
            # Calculate next review date
            import datetime
            next_review = datetime.datetime.now() + datetime.timedelta(days=interval)
            
            if self.client:
                # Update database with Supabase
                update_data = {
                    "confidence_level": confidence_level,
                    "ease_factor": ease_factor,
                    "interval": interval,
                    "repetitions": repetitions,
                    "next_review_date": next_review.isoformat(),
                    "updated_at": datetime.datetime.now().isoformat()
                }
                
                result = self.client.table("user_progress") \
                    .update(update_data) \
                    .eq("id", progress["id"]) \
                    .execute()
                
                return result.data[0] if result.data else None
            else:
                # Update in mock storage
                progress["confidence_level"] = confidence_level
                progress["repetitions"] = repetitions
                progress["ease_factor"] = ease_factor
                progress["interval"] = interval
                progress["next_review_date"] = next_review.isoformat()
                
                return progress
        except Exception as e:
            logger.error(f"Error updating card progress: {str(e)}")
            logger.error(traceback.format_exc())
            raise ServiceError(f"Failed to update card progress: {str(e)}")
    
    def get_due_cards(self, user_id, limit=20):
        """Get cards due for review for a user"""
        logger.info(f"Getting due cards for user {user_id}, limit {limit}")
        
        try:
            if self.client:
                # Use actual Supabase client
                import datetime
                now = datetime.datetime.now().isoformat()
                
                # First try to use the custom function if available
                try:
                    result = self.client.rpc(
                        "get_due_cards", 
                        {"user_uuid": user_id, "card_limit": limit}
                    ).execute()
                    
                    if result.data:
                        return result.data
                except Exception as func_error:
                    logger.warning(f"Failed to use get_due_cards function: {str(func_error)}")
                    
                # Fallback to direct query
                try:
                    # Get cards that are due for review with a join to the flashcards table
                    result = self.client.table("user_progress") \
                        .select("*, flashcards!inner(question, answer)") \
                        .eq("user_id", user_id) \
                        .lt("next_review_date", now) \
                        .order("next_review_date") \
                        .limit(limit) \
                        .execute()
                    
                    # Format the response to match the expected structure
                    due_cards = []
                    for item in result.data:
                        flashcard = item.get("flashcards", {})
                        due_cards.append({
                            "id": item["id"],
                            "card_id": item["card_id"],
                            "question": flashcard.get("question", ""),
                            "answer": flashcard.get("answer", ""),
                            "confidence_level": item["confidence_level"],
                            "next_review_date": item["next_review_date"]
                        })
                    
                    return due_cards
                except Exception as query_error:
                    logger.error(f"Error in fallback query: {str(query_error)}")
                    return []
            else:
                # In mock implementation, just return first few items from progress
                user_cards = [p for p in self._storage["user_progress"] if p["user_id"] == user_id]
                return user_cards[:limit]
        except Exception as e:
            logger.error(f"Error in get_due_cards: {str(e)}")
            logger.error(traceback.format_exc())
            return []
            
    def get_learning_stats(self, user_id):
        """Get user learning statistics"""
        logger.info(f"Getting learning stats for user {user_id}")
        
        try:
            if self.client:
                # Get cards learned count
                cards_result = self.client.table("user_progress") \
                    .select("id", count="exact") \
                    .eq("user_id", user_id) \
                    .execute()
                
                cards_learned = cards_result.count if hasattr(cards_result, 'count') else 0
                
                # Get average confidence
                confidence_result = self.client.table("user_progress") \
                    .select("confidence_level") \
                    .eq("user_id", user_id) \
                    .execute()
                
                confidence_levels = [item.get('confidence_level', 0) for item in confidence_result.data] if confidence_result.data else []
                average_confidence = sum(confidence_levels) / len(confidence_levels) if confidence_levels else 0
                
                # Get study streak
                import datetime
                one_week_ago = datetime.datetime.now() - datetime.timedelta(days=7)
                one_week_ago_str = one_week_ago.isoformat()
                
                sessions_result = self.client.table("study_sessions") \
                    .select("start_time") \
                    .eq("user_id", user_id) \
                    .gt("start_time", one_week_ago_str) \
                    .order("start_time", desc=True) \
                    .execute()
                
                # Count unique days
                days = set()
                for session in sessions_result.data:
                    session_date = datetime.datetime.fromisoformat(session['start_time'].replace('Z', '+00:00'))
                    days.add(session_date.date())
                
                streak_days = len(days)
                
                return {
                    'cardsLearned': cards_learned,
                    'averageConfidence': round(average_confidence, 2),
                    'streakDays': streak_days
                }
            else:
                # Return mock data
                return {
                    'cardsLearned': len(self._storage['user_progress']),
                    'averageConfidence': 3.5,
                    'streakDays': 3
                }
        except Exception as e:
            logger.error(f"Error getting learning stats: {str(e)}")
            logger.error(traceback.format_exc())
            return {
                'error': str(e),
                'cardsLearned': 0,
                'averageConfidence': 0,
                'streakDays': 0
            }
