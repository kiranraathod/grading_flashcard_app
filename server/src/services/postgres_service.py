import logging
from ..utils.db_helper import get_db_cursor
from ..utils.error_handler import ServiceError, NotFoundError, AuthorizationError

logger = logging.getLogger(__name__)

class PostgresService:
    """Service class for PostgreSQL database interactions"""
    
    def __init__(self):
        logger.info("PostgreSQL service initialized")
    
    def save_grade(self, user_id, flashcard_id, user_answer, grade, feedback, suggestions):
        """Save a grade result to PostgreSQL"""
        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO flashcard_grades 
                    (user_id, card_id, user_answer, grade, feedback, suggestions)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (user_id, flashcard_id, user_answer, grade, feedback, suggestions)
                )
                
                result = cursor.fetchone()
                return result
        except Exception as e:
            logger.error(f"Error saving grade to PostgreSQL: {str(e)}")
            return None
    
    def save_feedback(self, user_id, flashcard_id, feedback):
        """Save user feedback to PostgreSQL"""
        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    INSERT INTO user_feedback 
                    (user_id, card_id, feedback)
                    VALUES (%s, %s, %s)
                    RETURNING id
                    """,
                    (user_id, flashcard_id, feedback)
                )
                
                result = cursor.fetchone()
                return result
        except Exception as e:
            logger.error(f"Error saving feedback to PostgreSQL: {str(e)}")
            return None
    
    def get_user_progress(self, user_id, card_id):
        """Get user progress for a specific flashcard"""
        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    SELECT * FROM user_progress
                    WHERE user_id = %s AND card_id = %s
                    """,
                    (user_id, card_id)
                )
                
                result = cursor.fetchone()
                return result
        except Exception as e:
            logger.error(f"Error getting user progress from PostgreSQL: {str(e)}")
            return None
    
    def update_card_progress(self, user_id, card_id, confidence_level):
        """Update card progress using the SM-2 algorithm"""
        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    SELECT update_card_progress(%s, %s, %s)
                    """,
                    (user_id, card_id, confidence_level)
                )
                
                result = cursor.fetchone()
                return result
        except Exception as e:
            logger.error(f"Error updating card progress in PostgreSQL: {str(e)}")
            return None
    
    def get_due_cards(self, user_id, limit=20):
        """Get cards due for review for a user"""
        try:
            with get_db_cursor() as cursor:
                cursor.execute(
                    """
                    SELECT * FROM get_due_cards(%s, %s)
                    """,
                    (user_id, limit)
                )
                
                result = cursor.fetchall()
                return result
        except Exception as e:
            logger.error(f"Error getting due cards from PostgreSQL: {str(e)}")
            return []
            
    def get_learning_stats(self, user_id):
        """Get learning statistics for a user"""
        try:
            with get_db_cursor() as cursor:
                # Get cards learned count
                cursor.execute(
                    """
                    SELECT COUNT(*) AS cards_learned
                    FROM user_progress
                    WHERE user_id = %s
                    """,
                    (user_id,)
                )
                
                cards_learned_result = cursor.fetchone()
                cards_learned = cards_learned_result['cards_learned'] if cards_learned_result else 0
                
                # Get average confidence
                cursor.execute(
                    """
                    SELECT AVG(confidence_level) AS avg_confidence
                    FROM user_progress
                    WHERE user_id = %s
                    """,
                    (user_id,)
                )
                
                avg_confidence_result = cursor.fetchone()
                avg_confidence = avg_confidence_result['avg_confidence'] if avg_confidence_result and avg_confidence_result['avg_confidence'] else 0
                
                # Get study streak (days in the past week)
                cursor.execute(
                    """
                    SELECT COUNT(DISTINCT DATE(start_time)) AS streak_days
                    FROM study_sessions
                    WHERE user_id = %s
                    AND start_time > CURRENT_TIMESTAMP - INTERVAL '7 days'
                    """,
                    (user_id,)
                )
                
                streak_result = cursor.fetchone()
                streak_days = streak_result['streak_days'] if streak_result else 0
                
                return {
                    'cardsLearned': cards_learned,
                    'averageConfidence': round(float(avg_confidence), 2),
                    'streakDays': streak_days
                }
        except Exception as e:
            logger.error(f"Error getting learning stats from PostgreSQL: {str(e)}")
            return {
                'cardsLearned': 0,
                'averageConfidence': 0,
                'streakDays': 0
            }
            
    # Flashcard set methods
    def get_flashcard_sets(self, user_id=None):
        """Get all flashcard sets for a user or public sets"""
        try:
            with get_db_cursor() as cursor:
                if user_id:
                    query = """
                    SELECT fs.*, COUNT(f.id) AS card_count
                    FROM flashcard_sets fs
                    LEFT JOIN flashcards f ON fs.id = f.set_id
                    WHERE fs.user_id = %s OR fs.is_public = true
                    GROUP BY fs.id
                    ORDER BY fs.date_created DESC
                    """
                    cursor.execute(query, (user_id,))
                else:
                    query = """
                    SELECT fs.*, COUNT(f.id) AS card_count
                    FROM flashcard_sets fs
                    LEFT JOIN flashcards f ON fs.id = f.set_id
                    WHERE fs.is_public = true
                    GROUP BY fs.id
                    ORDER BY fs.date_created DESC
                    """
                    cursor.execute(query)
                
                sets = cursor.fetchall()
                
                # Get flashcards for each set
                for s in sets:
                    cursor.execute(
                        """
                        SELECT * FROM flashcards
                        WHERE set_id = %s
                        ORDER BY position
                        """,
                        (s['id'],)
                    )
                    s['flashcards'] = cursor.fetchall()
                
                return sets
        except Exception as e:
            logger.error(f"Error getting flashcard sets from PostgreSQL: {str(e)}")
            return []
    
    def get_flashcard_set(self, set_id, user_id=None):
        """Get a specific flashcard set"""
        try:
            with get_db_cursor() as cursor:
                if user_id:
                    query = """
                    SELECT * FROM flashcard_sets
                    WHERE id = %s AND (user_id = %s OR is_public = true)
                    """
                    cursor.execute(query, (set_id, user_id))
                else:
                    query = """
                    SELECT * FROM flashcard_sets
                    WHERE id = %s AND is_public = true
                    """
                    cursor.execute(query, (set_id,))
                
                set_data = cursor.fetchone()
                
                if not set_data:
                    raise NotFoundError(f"Flashcard set with ID {set_id} not found")
                
                # Get flashcards
                cursor.execute(
                    """
                    SELECT * FROM flashcards
                    WHERE set_id = %s
                    ORDER BY position
                    """,
                    (set_id,)
                )
                
                set_data['flashcards'] = cursor.fetchall()
                return set_data
        except NotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error getting flashcard set from PostgreSQL: {str(e)}")
            raise ServiceError(f"Error retrieving flashcard set: {str(e)}")
    
    def create_flashcard_set(self, user_id, set_data):
        """Create a new flashcard set"""
        try:
            with get_db_cursor() as cursor:
                # Create the set
                cursor.execute(
                    """
                    INSERT INTO flashcard_sets
                    (title, description, is_draft, is_public, user_id)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING *
                    """,
                    (
                        set_data['title'],
                        set_data.get('description', ''),
                        set_data.get('is_draft', True),
                        set_data.get('is_public', False),
                        user_id
                    )
                )
                
                new_set = cursor.fetchone()
                set_id = new_set['id']
                
                # Create flashcards if any
                if 'flashcards' in set_data and set_data['flashcards']:
                    for i, card in enumerate(set_data['flashcards']):
                        cursor.execute(
                            """
                            INSERT INTO flashcards
                            (set_id, question, answer, hint, image_url, position)
                            VALUES (%s, %s, %s, %s, %s, %s)
                            """,
                            (
                                set_id,
                                card.get('question', ''),
                                card.get('answer', ''),
                                card.get('hint'),
                                card.get('image_url'),
                                i
                            )
                        )
                
                # Get the full set with flashcards
                cursor.execute(
                    """
                    SELECT * FROM flashcards
                    WHERE set_id = %s
                    ORDER BY position
                    """,
                    (set_id,)
                )
                
                new_set['flashcards'] = cursor.fetchall()
                return new_set
        except Exception as e:
            logger.error(f"Error creating flashcard set in PostgreSQL: {str(e)}")
            raise ServiceError(f"Error creating flashcard set: {str(e)}")
    
    def update_flashcard_set(self, set_id, user_id, set_data):
        """Update a flashcard set"""
        try:
            with get_db_cursor() as cursor:
                # Check ownership
                cursor.execute(
                    """
                    SELECT id FROM flashcard_sets
                    WHERE id = %s AND user_id = %s
                    """,
                    (set_id, user_id)
                )
                
                if not cursor.fetchone():
                    raise AuthorizationError("You don't have permission to update this flashcard set")
                
                # Update the set
                cursor.execute(
                    """
                    UPDATE flashcard_sets
                    SET
                        title = %s,
                        description = %s,
                        is_draft = %s,
                        is_public = %s,
                        last_updated = CURRENT_TIMESTAMP
                    WHERE id = %s
                    RETURNING *
                    """,
                    (
                        set_data['title'],
                        set_data.get('description', ''),
                        set_data.get('is_draft', True),
                        set_data.get('is_public', False),
                        set_id
                    )
                )
                
                updated_set = cursor.fetchone()
                
                # Delete existing flashcards
                cursor.execute(
                    """
                    DELETE FROM flashcards
                    WHERE set_id = %s
                    """,
                    (set_id,)
                )
                
                # Create new flashcards
                if 'flashcards' in set_data and set_data['flashcards']:
                    for i, card in enumerate(set_data['flashcards']):
                        cursor.execute(
                            """
                            INSERT INTO flashcards
                            (set_id, question, answer, hint, image_url, position)
                            VALUES (%s, %s, %s, %s, %s, %s)
                            """,
                            (
                                set_id,
                                card.get('question', ''),
                                card.get('answer', ''),
                                card.get('hint'),
                                card.get('image_url'),
                                i
                            )
                        )
                
                # Get the updated flashcards
                cursor.execute(
                    """
                    SELECT * FROM flashcards
                    WHERE set_id = %s
                    ORDER BY position
                    """,
                    (set_id,)
                )
                
                updated_set['flashcards'] = cursor.fetchall()
                return updated_set
        except AuthorizationError:
            raise
        except Exception as e:
            logger.error(f"Error updating flashcard set in PostgreSQL: {str(e)}")
            raise ServiceError(f"Error updating flashcard set: {str(e)}")
    
    def delete_flashcard_set(self, set_id, user_id):
        """Delete a flashcard set"""
        try:
            with get_db_cursor() as cursor:
                # Check ownership
                cursor.execute(
                    """
                    SELECT id FROM flashcard_sets
                    WHERE id = %s AND user_id = %s
                    """,
                    (set_id, user_id)
                )
                
                if not cursor.fetchone():
                    raise AuthorizationError("You don't have permission to delete this flashcard set")
                
                # Delete the set (cascade will delete flashcards)
                cursor.execute(
                    """
                    DELETE FROM flashcard_sets
                    WHERE id = %s
                    """,
                    (set_id,)
                )
                
                return {'success': True}
        except AuthorizationError:
            raise
        except Exception as e:
            logger.error(f"Error deleting flashcard set in PostgreSQL: {str(e)}")
            raise ServiceError(f"Error deleting flashcard set: {str(e)}")
    
    def rate_flashcard_set(self, set_id, user_id, rating):
        """Rate a flashcard set"""
        try:
            with get_db_cursor() as cursor:
                # Get current rating
                cursor.execute(
                    """
                    SELECT rating, rating_count
                    FROM flashcard_sets
                    WHERE id = %s
                    """,
                    (set_id,)
                )
                
                result = cursor.fetchone()
                if not result:
                    raise NotFoundError(f"Flashcard set with ID {set_id} not found")
                
                current_rating = result['rating'] or 0
                current_count = result['rating_count'] or 0
                
                # Calculate new rating
                new_count = current_count + 1
                new_rating = ((current_rating * current_count) + rating) / new_count
                
                # Update rating
                cursor.execute(
                    """
                    UPDATE flashcard_sets
                    SET rating = %s, rating_count = %s
                    WHERE id = %s
                    RETURNING rating, rating_count
                    """,
                    (new_rating, new_count, set_id)
                )
                
                return cursor.fetchone()
        except NotFoundError:
            raise
        except Exception as e:
            logger.error(f"Error rating flashcard set in PostgreSQL: {str(e)}")
            raise ServiceError(f"Error rating flashcard set: {str(e)}")
