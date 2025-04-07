from dotenv import load_dotenv
import os
import json
import asyncio
import logging
import traceback
import re
import sys

# Load environment variables
load_dotenv()

# Set up logger
logging.basicConfig(level=logging.DEBUG, handlers=[logging.StreamHandler(sys.stdout)])
logger = logging.getLogger(__name__)

class LLMConnectionError(Exception):
    """Custom exception for LLM connection issues"""
    pass

class LLMService:
    def __init__(self):
        self.model = os.getenv('LLM_MODEL', 'gemini-2.0-flash')
        try:
            self._init_client()
            self.is_connected = True
            logger.debug(f"LLMService initialized with model: {self.model}")
        except Exception as e:
            self.is_connected = False
            logger.error(f"Failed to initialize LLM service: {str(e)}")

    def _init_client(self):
        """Initialize the Google Gemini client"""
        try:
            import google.generativeai as genai
            api_key = os.getenv('GOOGLE_API_KEY')
            if not api_key:
                raise ValueError("GOOGLE_API_KEY environment variable is not set")
            
            genai.configure(api_key=api_key)
            self.client = genai
            logger.info(f"Google GenerativeAI client initialized with model: {self.model}")
        except ImportError as e:
            logger.error(f"Failed to import google.generativeai. Make sure it's installed: {e}")
            raise
        except Exception as e:
            logger.error(f"Error initializing Google Gemini client: {str(e)}")
            logger.error(traceback.format_exc())
            raise
    
    async def grade_answer(self, question, user_answer):
        """Grade the user's answer using Gemini"""
        logger.debug(f"grade_answer called with question='{question}', answer='{user_answer}'")
        
        # Check if LLM service is connected
        if not self.is_connected:
            logger.error("LLM service is not connected")
            raise LLMConnectionError("LLM service is not connected")
        
        try:
            # Use the LLM for grading
            logger.debug("Attempting to use LLM for grading")
            response = await self._grade_answer_sync(question, user_answer)
            logger.debug(f"Received processed response from API: {response}")
            
            # Normalize the grade (remove + or -)
            if 'grade' in response:
                # Extract just the letter part (A, B, C, D, F)
                response['grade'] = response['grade'][0]
            
            # Validate response structure
            if self._validate_response(response):
                # Fix mathematical symbols in the response
                response = self._fix_mathematical_symbols(response)
                return response
            else:
                logger.error("LLM returned invalid response format")
                raise LLMConnectionError("LLM returned invalid response format")
                
        except Exception as e:
            logger.error(f"Error during grading: {str(e)}")
            logger.error(traceback.format_exc())
            
            # Raise exception instead of falling back to mock implementation
            raise LLMConnectionError(f"LLM grading failed: {str(e)}")
    
    def _fix_mathematical_symbols(self, response):
        """Fix common mathematical symbols in the response for better display"""
        def fix_text(text):
            # Fix π symbol
            text = text.replace('π', 'pi')
            text = text.replace('Ï', 'pi')
            
            # Fix squared notation
            text = text.replace('²', '^2')
            text = text.replace('Â²', '^2')
            text = text.replace('³', '^3')
            text = text.replace('Â³', '^3')
            
            # Fix multiplication symbol
            text = text.replace('×', '*')
            text = text.replace('Ã', '*')
            
            # Fix division symbol
            text = text.replace('÷', '/')
            
            # Fix square/cube root symbols
            text = text.replace('√', 'sqrt')
            text = text.replace('∛', 'cbrt')
            
            # Fix inequality symbols
            text = text.replace('≤', '<=')
            text = text.replace('≥', '>=')
            text = text.replace('≠', '!=')
            
            # Fix Greek letters often used in math
            text = text.replace('θ', 'theta')
            text = text.replace('Θ', 'Theta')
            text = text.replace('σ', 'sigma')
            text = text.replace('Σ', 'Sigma')
            text = text.replace('δ', 'delta')
            text = text.replace('Δ', 'Delta')
            text = text.replace('μ', 'mu')
            text = text.replace('α', 'alpha')
            text = text.replace('β', 'beta')
            text = text.replace('γ', 'gamma')
            text = text.replace('Γ', 'Gamma')
            text = text.replace('ω', 'omega')
            text = text.replace('Ω', 'Omega')
            
            # Fix common mathematical patterns
            text = re.sub(r'πr²|πr\^2|pir²|pir\^2|Ïr²|ÏrÂ²', 'pi*r^2', text)
            text = re.sub(r'a²\+b²|aÂ²\+bÂ²', 'a^2+b^2', text)
            
            return text
        
        # Apply fixes to feedback
        if 'feedback' in response:
            response['feedback'] = fix_text(response['feedback'])
        
        # Apply fixes to suggestions
        if 'suggestions' in response and isinstance(response['suggestions'], list):
            response['suggestions'] = [fix_text(suggestion) for suggestion in response['suggestions']]
            
        return response
    
    def _validate_response(self, response):
        """Validate that the response has the expected structure"""
        required_keys = ['grade', 'feedback', 'suggestions']
        
        # Check if all required keys exist
        if not all(key in response for key in required_keys):
            logger.error(f"Missing keys in response. Found: {list(response.keys())}")
            return False
        
        # Check if grade is valid
        if response['grade'] not in ['A', 'B', 'C', 'D', 'F']:
            logger.error(f"Invalid grade: {response['grade']}")
            return False
            
        # Check if suggestions is a list
        if not isinstance(response['suggestions'], list) or len(response['suggestions']) == 0:
            logger.error(f"Invalid suggestions format: {response['suggestions']}")
            return False
            
        return True
    
    async def _grade_answer_sync(self, question, user_answer):
        """Synchronous implementation of grading to avoid asyncio issues"""
        # Format the prompt
        prompt = f"""
        You are a precise and helpful grading assistant. 
        
        Question: {question}
        
        Student's Answer: {user_answer}
        
        Please grade this answer and provide constructive feedback. Be specific about why the answer is correct or incorrect.
        
        When referring to mathematical formulas, use simple text notation like "pi*r^2" for πr² to avoid encoding issues.
        Also, avoid using × symbol for multiplication, use * instead.
        
        Your response should be in JSON format with the following structure:
        {{
            "grade": [A single letter grade: A, B, C, D, or F only - no + or - modifiers],
            "feedback": [Detailed feedback on the answer's strengths and weaknesses],
            "suggestions": [Array of 2-3 specific suggestions for improvement]
        }}
        
        Return only the JSON object, nothing else.
        """
        
        # Setup the model
        try:
            model = self.client.GenerativeModel(self.model)
            logger.debug(f"Initialized model: {self.model}")
        except Exception as e:
            logger.error(f"Error initializing model: {str(e)}")
            logger.error(traceback.format_exc())
            raise LLMConnectionError(f"Failed to initialize LLM model: {str(e)}")
        
        # Generate content
        logger.debug("Sending request to Gemini API...")
        
        def generate_content():
            try:
                logger.debug("In generate_content function...")
                response = model.generate_content(prompt)
                logger.debug(f"Received response from Gemini")
                return response.text
            except Exception as e:
                logger.error(f"Error in generate_content: {str(e)}")
                logger.error(traceback.format_exc())
                raise
            
        # Use asyncio.to_thread to run the synchronous code
        try:
            logger.debug("Calling asyncio.to_thread with generate_content...")
            content = await asyncio.to_thread(generate_content)
            logger.debug(f"Processing content from API response")
        except Exception as e:
            logger.error(f"Error in asyncio.to_thread: {str(e)}")
            logger.error(traceback.format_exc())
            raise LLMConnectionError(f"Failed to connect to LLM API: {str(e)}")
        
        # Parse the content
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
            result = json.loads(content)
            logger.debug(f"Successfully parsed JSON result: {result}")
            
            # Ensure suggestions is a list
            if 'suggestions' in result and not isinstance(result['suggestions'], list):
                if isinstance(result['suggestions'], str):
                    # Convert string to list
                    result['suggestions'] = [result['suggestions']]
                else:
                    # Default empty list
                    result['suggestions'] = []
                    
            return result
        except Exception as e:
            logger.error(f"Error parsing JSON: {str(e)}")
            logger.error(f"Raw content: {content}")
            raise LLMConnectionError(f"Failed to parse LLM response: {str(e)}")
    

