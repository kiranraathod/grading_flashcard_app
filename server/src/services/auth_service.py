import os
import logging
import jwt
import datetime
import bcrypt
import psycopg2
from ..utils.error_handler import AuthenticationError, ServiceError
from ..utils.db_helper import get_db_cursor
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '.env.local'))

logger = logging.getLogger(__name__)

class AuthService:
    """Service class for authentication"""
    
    def __init__(self):
        self.jwt_secret = os.getenv("JWT_SECRET", "your-secret-key-change-me")
        self.token_expiry = int(os.getenv("TOKEN_EXPIRY_HOURS", "24"))
        
    def register(self, email, password):
        """Register a new user"""
        try:
            # Hash password
            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            
            # Store in database
            with get_db_cursor() as cursor:
                cursor.execute(
                    "INSERT INTO users (email, password_hash) VALUES (%s, %s) RETURNING id",
                    (email, hashed_password)
                )
                
                result = cursor.fetchone()
                user_id = result['id']
            
            # Generate JWT token
            token = self.generate_token(user_id, email)
            
            return {
                'user': {
                    'id': str(user_id),
                    'email': email
                },
                'token': token
            }
        except psycopg2.errors.UniqueViolation:
            raise ServiceError("Email already registered", 400)
        except Exception as e:
            logger.error(f"Error during registration: {str(e)}")
            raise ServiceError("Registration failed", 500)
    
    def login(self, email, password):
        """Login a user"""
        try:
            # Get user from database
            with get_db_cursor() as cursor:
                cursor.execute(
                    "SELECT id, password_hash FROM users WHERE email = %s",
                    (email,)
                )
                
                result = cursor.fetchone()
                if not result:
                    raise AuthenticationError("Invalid email or password", 401)
                    
                user_id = result['id']
                stored_hash = result['password_hash']
            
            # Verify password
            if not bcrypt.checkpw(password.encode('utf-8'), stored_hash.encode('utf-8')):
                raise AuthenticationError("Invalid email or password", 401)
            
            # Generate JWT token
            token = self.generate_token(user_id, email)
            
            return {
                'user': {
                    'id': str(user_id),
                    'email': email
                },
                'token': token
            }
        except AuthenticationError as e:
            raise e
        except Exception as e:
            logger.error(f"Error during login: {str(e)}")
            raise ServiceError("Login failed", 500)
    
    def verify_token(self, token):
        """Verify a JWT token"""
        try:
            payload = jwt.decode(
                token, 
                self.jwt_secret, 
                algorithms=["HS256"]
            )
            return payload
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Token expired", 401)
        except jwt.InvalidTokenError:
            raise AuthenticationError("Invalid token", 401)
    
    def generate_token(self, user_id, email):
        """Generate a new JWT token"""
        expiry = datetime.datetime.utcnow() + datetime.timedelta(hours=self.token_expiry)
        payload = {
            'sub': str(user_id),
            'email': email,
            'exp': expiry
        }
        return jwt.encode(payload, self.jwt_secret, algorithm="HS256")
