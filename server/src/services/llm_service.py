"""
LLM service for interacting with Google's Gemini model.
"""
import json
import asyncio
import logging
import re
import sys
import traceback
from typing import Dict, Any, List

# Import from our custom modules
from src.config.config import config
from src.utils.exceptions import (
    LLMConnectionError,
    LLMResponseParsingError,
    InvalidInputError
)

# Set up logger
logger = logging.getLogger(__name__)

class LLMService:
    """Service for interacting with Google's Gemini model."""
    
    def __init__(self):
        """Initialize the LLM service."""
        self.model = config.LLM_MODEL
        self.timeout = config.LLM_TIMEOUT
        self.max_tokens = config.LLM_MAX_TOKENS
        self.temperature = config.LLM_TEMPERATURE
        
        try:
            self._init_client()
            self.is_connected = True
            logger.info(f"LLMService initialized with model: {self.model}")
        except Exception as e:
            self.is_connected = False
            logger.error(f"Failed to initialize LLM service: {str(e)}")
            # We don't raise here to allow the service to start even if LLM is not available

    def _init_client(self) -> None:
        """Initialize the Google Gemini client with error handling."""
        try:
            import google.generativeai as genai
            
            if not config.GOOGLE_API_KEY:
                raise InvalidInputError("GOOGLE_API_KEY environment variable is not set")
            
            genai.configure(api_key=config.GOOGLE_API_KEY)
            self.client = genai
            logger.info(f"Google GenerativeAI client initialized with model: {self.model}")
        except ImportError as e:
            error_msg = f"Failed to import google.generativeai. Make sure it's installed: {e}"
            logger.error(error_msg)
            raise LLMConnectionError(error_msg, status_code=500)
        except Exception as e:
            error_msg = f"Error initializing Google Gemini client: {str(e)}"
            logger.error(error_msg)
            logger.error(traceback.format_exc())
            raise LLMConnectionError(error_msg, status_code=500)
    
    async def grade_answer(self, question: str, user_answer: str, correct_answer: str) -> Dict[str, Any]:
        """
        Grade the user's answer using Gemini LLM.
        
        Args:
            question: The flashcard question
            user_answer: The user's answer to grade
            correct_answer: The correct answer from the flashcard
            
        Returns:
            Dict containing grade, feedback, and suggestions
            
        Raises:
            LLMConnectionError: If there's a problem connecting to the LLM service
            LLMResponseParsingError: If there's a problem parsing the LLM response
        """
        logger.debug(f"grade_answer called with question='{question}', answer='{user_answer}', correct_answer='{correct_answer}'")
        
        # Check if LLM service is connected
        if not self.is_connected:
            logger.error("LLM service is not connected")
            raise LLMConnectionError("LLM service is not connected", status_code=503)
        
        try:
            # Use the LLM for grading
            logger.debug("Attempting to use LLM for grading")
            response = await self._execute_grading_request(question, user_answer, correct_answer)
            logger.debug(f"Received processed response from API: {response}")
            
            # Normalize the score (ensure it's an integer within valid range)
            if 'score' in response:
                # Ensure score is an integer and clamp to 0-100 range
                try:
                    score = int(float(response['score']))  # Handle both int and float responses
                    response['score'] = max(0, min(100, score))  # Clamp to 0-100 range
                except (ValueError, TypeError):
                    logger.warning(f"Invalid score format: {response['score']}, defaulting to 50")
                    response['score'] = 50  # Default neutral score for invalid responses
            
            # Validate response structure
            self._validate_response(response)
            
            # Fix mathematical symbols in the response
            response = self._fix_mathematical_symbols(response)
            return response
        except LLMConnectionError:
            # Re-raise LLMConnectionError without wrapping
            raise
        except LLMResponseParsingError:
            # Re-raise LLMResponseParsingError without wrapping
            raise
        except Exception as e:
            logger.error(f"Unexpected error during grading: {str(e)}")
            logger.error(traceback.format_exc())
            raise LLMConnectionError(f"Unexpected error during grading: {str(e)}", status_code=500)
    
    def _fix_mathematical_symbols(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """
        Fix common mathematical symbols in the response for better display.
        
        Args:
            response: The response dictionary containing feedback and suggestions
            
        Returns:
            Updated response with fixed mathematical symbols
        """
        def fix_text(text: str) -> str:
            """Helper function to fix text with mathematical symbols."""
            replacements = {
                # Greek letters
                'π': 'pi', 'Ï': 'pi', 'θ': 'theta', 'Θ': 'Theta',
                'σ': 'sigma', 'Σ': 'Sigma', 'δ': 'delta', 'Δ': 'Delta',
                'μ': 'mu', 'α': 'alpha', 'β': 'beta', 'γ': 'gamma',
                'Γ': 'Gamma', 'ω': 'omega', 'Ω': 'Omega',
                
                # Mathematical operators and symbols
                '²': '^2', 'Â²': '^2', '³': '^3', 'Â³': '^3',
                '×': '*', 'Ã': '*', '÷': '/', '√': 'sqrt', '∛': 'cbrt',
                '≤': '<=', '≥': '>=', '≠': '!=',
            }
            
            # Apply simple replacements
            for old, new in replacements.items():
                text = text.replace(old, new)
            
            # Fix common mathematical patterns with regex
            patterns = {
                r'πr²|πr\^2|pir²|pir\^2|Ïr²|ÏrÂ²': 'pi*r^2',
                r'a²\+b²|aÂ²\+bÂ²': 'a^2+b^2',
            }
            
            for pattern, replacement in patterns.items():
                text = re.sub(pattern, replacement, text)
            
            return text
        
        # Apply fixes to feedback
        if 'feedback' in response:
            response['feedback'] = fix_text(response['feedback'])
        
        # Apply fixes to suggestions
        if 'suggestions' in response and isinstance(response['suggestions'], list):
            response['suggestions'] = [fix_text(suggestion) for suggestion in response['suggestions']]
            
        return response
    
    def _validate_response(self, response: Dict[str, Any]) -> None:
        """
        Validate that the response has the expected structure.
        
        Args:
            response: The response dictionary to validate
            
        Raises:
            LLMResponseParsingError: If the response is invalid
        """
        required_keys = ['score', 'feedback', 'suggestions']
        
        # Check if all required keys exist
        missing_keys = [key for key in required_keys if key not in response]
        if missing_keys:
            error_msg = f"Missing keys in response: {missing_keys}"
            logger.error(error_msg)
            raise LLMResponseParsingError(error_msg)
        
        # Check if score is valid
        if not isinstance(response['score'], (int, float)) or response['score'] < 0 or response['score'] > 100:
            error_msg = f"Invalid score: {response['score']}. Must be between 0 and 100"
            logger.error(error_msg)
            raise LLMResponseParsingError(error_msg)
            
        # Check if suggestions is a list
        if not isinstance(response['suggestions'], list):
            error_msg = f"Invalid suggestions format: {response['suggestions']}"
            logger.error(error_msg)
            raise LLMResponseParsingError(error_msg)
            
        # If suggestions array is empty, add default suggestions based on score
        if len(response['suggestions']) == 0:
            logger.warning("Empty suggestions array detected, adding default suggestions")
            if response['score'] >= 90:
                response['suggestions'] = [
                    "Continue practicing to maintain your understanding",
                    "Try applying this knowledge to more complex problems",
                    "Consider exploring related topics to deepen your understanding"
                ]
            else:
                response['suggestions'] = [
                    "Review the core concepts related to this topic",
                    "Practice with similar problems to reinforce your understanding",
                    "Consider creating additional flashcards on this subject"
                ]
    
    async def grade_interview_answer(self, prompt: str) -> Dict[str, Any]:
        """
        Grade an interview answer using Gemini LLM.
        
        Args:
            prompt: Complete prompt with question, answer, and evaluation criteria
            
        Returns:
            Dict containing score, feedback, and suggestions
            
        Raises:
            LLMConnectionError: If there's a problem connecting to the LLM service
            LLMResponseParsingError: If there's a problem parsing the LLM response
        """
        logger.debug(f"grade_interview_answer called with prompt length: {len(prompt)}")
        
        # Check if LLM service is connected
        if not self.is_connected:
            logger.error("LLM service is not connected")
            raise LLMConnectionError("LLM service is not connected", status_code=503)
        
        try:
            # Setup the model with slightly higher temperature for more creative feedback
            interview_temperature = max(self.temperature, 0.3)  # Minimum 0.3 temperature for interviews
            
            model = self.client.GenerativeModel(
                self.model,
                generation_config={
                    "temperature": interview_temperature,
                    "max_output_tokens": self.max_tokens,
                }
            )
            logger.debug(f"Initialized model for interview grading: {self.model} with temperature {interview_temperature}")
            
            # Generate content with timeout protection
            logger.debug("Sending interview grading request to Gemini API...")
            
            try:
                # Use asyncio.to_thread to run the synchronous API call without blocking
                content = await asyncio.wait_for(
                    asyncio.to_thread(lambda: model.generate_content(prompt).text),
                    timeout=self.timeout
                )
                logger.debug(f"Received raw content from API: {content[:100]}...")
            except asyncio.TimeoutError:
                logger.error(f"LLM request timed out after {self.timeout} seconds")
                raise LLMConnectionError(f"LLM request timed out after {self.timeout} seconds", status_code=504)
            except Exception as e:
                logger.error(f"Error generating content: {str(e)}")
                logger.error(traceback.format_exc())
                raise LLMConnectionError(f"Error generating content: {str(e)}")
            
            # Parse the interview assessment response
            return self._parse_interview_response(content)
            
        except LLMConnectionError:
            # Re-raise LLMConnectionError without wrapping
            raise
        except LLMResponseParsingError:
            # Re-raise LLMResponseParsingError without wrapping
            raise
        except Exception as e:
            logger.error(f"Unexpected error during interview assessment: {str(e)}")
            logger.error(traceback.format_exc())
            raise LLMConnectionError(f"Unexpected error during interview assessment: {str(e)}", status_code=500)
    
    def _parse_interview_response(self, content: str) -> Dict[str, Any]:
        """
        Parse the interview assessment response from the LLM.
        
        Args:
            content: The raw response from the LLM
            
        Returns:
            Dict containing score, feedback, and suggestions
            
        Raises:
            LLMResponseParsingError: If there's a problem parsing the response
        """
        try:
            # Clean up the content - handle various response formats
            # Remove markdown code blocks if present
            if '```json' in content:
                content = re.search(r'```json\s*(.*?)\s*```', content, re.DOTALL)
                if content:
                    content = content.group(1)
            elif '```' in content:
                content = re.search(r'```\s*(.*?)\s*```', content, re.DOTALL)
                if content:
                    content = content.group(1)
            
            # Try to find JSON-like structure if still not clean
            if '{' in content and '}' in content:
                content = content[content.find('{'):content.rfind('}')+1]
                
            # Clean up any trailing or leading non-JSON text
            content = content.strip()
            
            # Parse JSON
            try:
                result = json.loads(content)
                logger.debug(f"Successfully parsed JSON interview result: {result}")
            except json.JSONDecodeError as json_error:
                logger.error(f"JSON parsing error: {str(json_error)}")
                logger.error(f"Raw content: {content}")
                raise LLMResponseParsingError(f"Failed to parse JSON: {str(json_error)}")
            
            # Validate interview response
            self._validate_interview_response(result)
            
            return result
            
        except LLMResponseParsingError:
            # Re-raise without wrapping
            raise
        except Exception as e:
            logger.error(f"Error processing LLM interview response: {str(e)}")
            logger.error(f"Raw content: {content}")
            raise LLMResponseParsingError(f"Failed to process LLM interview response: {str(e)}")
    
    def _validate_interview_response(self, response: Dict[str, Any]) -> None:
        """
        Validate that the interview response has the expected structure.
        
        Args:
            response: The response dictionary to validate
            
        Raises:
            LLMResponseParsingError: If the response is invalid
        """
        # Check required fields
        required_fields = ['score', 'feedback', 'suggestions']
        missing_fields = [field for field in required_fields if field not in response]
        
        if missing_fields:
            raise LLMResponseParsingError(f"Missing required fields in interview response: {missing_fields}")
        
        # Validate score
        if not isinstance(response['score'], (int, float)) or response['score'] < 0 or response['score'] > 100:
            raise LLMResponseParsingError(f"Invalid score in interview response: {response['score']}")
        
        # Validate feedback
        if not isinstance(response['feedback'], str) or not response['feedback'].strip():
            raise LLMResponseParsingError("Missing or invalid feedback in interview response")
        
        # Validate suggestions
        if not isinstance(response['suggestions'], list) or not response['suggestions']:
            raise LLMResponseParsingError("Missing or invalid suggestions in interview response")
        
        # Ensure suggestions are strings
        for i, suggestion in enumerate(response['suggestions']):
            if not isinstance(suggestion, str) or not suggestion.strip():
                raise LLMResponseParsingError(f"Invalid suggestion at index {i} in interview response")
                
    async def _execute_grading_request(self, question: str, user_answer: str, correct_answer: str) -> Dict[str, Any]:
        """
        Execute the grading request to the LLM with improved error handling.
        
        Args:
            question: The flashcard question
            user_answer: The user's answer to grade
            correct_answer: The correct answer from the flashcard
            
        Returns:
            Dict containing grade, feedback, and suggestions
            
        Raises:
            LLMConnectionError: If there's a problem connecting to the LLM service
            LLMResponseParsingError: If there's a problem parsing the LLM response
        """
        # Format the prompt with explicit JSON structure to reduce parsing issues
        prompt = f"""
        You are a precise, helpful, and encouraging grading assistant. You will evaluate a student's answer against the correct answer provided on a flashcard.
        
        Question: {question}
        
        Correct Answer: {correct_answer}
        
        Student's Answer: {user_answer}
        
        GRADING INSTRUCTIONS:
        1. Consider semantic equivalence - if the student's answer conveys the same meaning as the correct answer, it should be considered correct even if phrased differently.
        2. Ignore minor differences in capitalization, punctuation, and formatting unless they change the meaning.
        3. For mathematical answers, accept equivalent forms (e.g., "1/2" and "0.5" are equivalent).
        4. For factual answers, focus on the key concepts rather than exact wording.
        
        SCORING SCALE (0-100):
        - 90-100: The answer is completely correct or semantically equivalent to the correct answer.
        - 80-89: The answer is mostly correct with minor omissions or inaccuracies.
        - 70-79: The answer shows good understanding with some gaps or minor errors.
        - 60-69: The answer shows partial understanding with significant issues.
        - 50-59: The answer shows minimal understanding with major errors.
        - 0-49: The answer is mostly or completely incorrect or shows fundamental misunderstanding.
        
        When providing feedback, be specific about the comparison between the student's answer and the correct answer. Always include encouraging language, even for incorrect answers.
        
        When referring to mathematical formulas, use simple text notation like "pi*r^2" for πr² to avoid encoding issues.
        Also, avoid using * instead of × for multiplication.
        
        Your response must strictly conform to this JSON format:
        {{
            "score": NUMERICAL_SCORE,
            "feedback": "DETAILED_FEEDBACK",
            "suggestions": ["SUGGESTION_1", "SUGGESTION_2", "SUGGESTION_3"]
        }}
        
        Where:
        - NUMERICAL_SCORE must be an integer between 0 and 100 based on how well the student's answer matches the correct answer
        - DETAILED_FEEDBACK must include specific comparison to the correct answer and encouragement
        - There must be 2-3 specific suggestions in the suggestions array that help the student improve
        
        For excellent answers (score 90+), provide suggestions that extend the student's knowledge.
        For other scores, provide targeted suggestions to help improve understanding of the concept.
        
        Do not include any explanations, markdown formatting or any text outside the JSON structure.
        Return only the valid JSON object, nothing else.
        """
        
        # Setup the model
        try:
            model = self.client.GenerativeModel(
                self.model,
                generation_config={
                    "temperature": self.temperature,
                    "max_output_tokens": self.max_tokens,
                }
            )
            logger.debug(f"Initialized model: {self.model}")
        except Exception as e:
            logger.error(f"Error initializing model: {str(e)}")
            logger.error(traceback.format_exc())
            raise LLMConnectionError(f"Failed to initialize LLM model: {str(e)}")
        
        # Generate content with timeout protection
        logger.debug("Sending request to Gemini API...")
        
        async def generate_with_timeout():
            """Generate content with timeout protection."""
            try:
                # Use asyncio.to_thread to run the synchronous API call without blocking
                return await asyncio.wait_for(
                    asyncio.to_thread(lambda: model.generate_content(prompt).text),
                    timeout=self.timeout
                )
            except asyncio.TimeoutError:
                logger.error(f"LLM request timed out after {self.timeout} seconds")
                raise LLMConnectionError(f"LLM request timed out after {self.timeout} seconds", status_code=504)
            except Exception as e:
                logger.error(f"Error generating content: {str(e)}")
                logger.error(traceback.format_exc())
                raise LLMConnectionError(f"Error generating content: {str(e)}")
            
        try:
            logger.debug("Executing LLM request with timeout...")
            content = await generate_with_timeout()
            logger.debug(f"Received raw content from API: {content[:100]}...")
        except LLMConnectionError:
            # Re-raise without wrapping
            raise
        except Exception as e:
            logger.error(f"Unexpected error in generate_with_timeout: {str(e)}")
            logger.error(traceback.format_exc())
            raise LLMConnectionError(f"Failed to connect to LLM API: {str(e)}")
        
        # Parse the content with improved error handling
        try:
            # Clean up the content - handle various response formats
            # Remove markdown code blocks if present
            if '```json' in content:
                content = re.search(r'```json\s*(.*?)\s*```', content, re.DOTALL)
                if content:
                    content = content.group(1)
            elif '```' in content:
                content = re.search(r'```\s*(.*?)\s*```', content, re.DOTALL)
                if content:
                    content = content.group(1)
            
            # Try to find JSON-like structure if still not clean
            if '{' in content and '}' in content:
                content = content[content.find('{'):content.rfind('}')+1]
                
            # Clean up any trailing or leading non-JSON text
            content = content.strip()
            
            # Parse JSON
            try:
                result = json.loads(content)
                logger.debug(f"Successfully parsed JSON result: {result}")
            except json.JSONDecodeError as json_error:
                logger.error(f"JSON parsing error: {str(json_error)}")
                logger.error(f"Raw content: {content}")
                raise LLMResponseParsingError(f"Failed to parse JSON: {str(json_error)}")
            
            # Ensure suggestions is a list
            if 'suggestions' in result and not isinstance(result['suggestions'], list):
                if isinstance(result['suggestions'], str):
                    # Convert string to list
                    result['suggestions'] = [result['suggestions']]
                else:
                    # Default empty list
                    result['suggestions'] = []
                    
            return result
        except LLMResponseParsingError:
            # Re-raise without wrapping
            raise
        except Exception as e:
            logger.error(f"Error processing LLM response: {str(e)}")
            logger.error(f"Raw content: {content}")
            raise LLMResponseParsingError(f"Failed to process LLM response: {str(e)}")
