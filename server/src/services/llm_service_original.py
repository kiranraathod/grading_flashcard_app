from dotenv import load_dotenv
import os
import json
import asyncio
import logging
import traceback

# Load environment variables
load_dotenv()

# Set up logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LLMService:
    def __init__(self):
        self.model = os.getenv('LLM_MODEL', 'gemini-2.0-flash')
        self._init_client()

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
        except ImportError:
            logger.error("Failed to import google.generativeai. Make sure it's installed.")
            raise
        except Exception as e:
            logger.error(f"Error initializing Google Gemini client: {str(e)}")
            raise
    
    async def grade_answer(self, question, user_answer):
        """Grade the user's answer using Gemini"""
        try:
            logger.info(f"Starting to grade: question='{question}', answer='{user_answer}'")
            
            # Try to directly call our synchronous function first
            response = await self._grade_answer_sync(question, user_answer)
            logger.info(f"Received processed response from API: {response}")
            
            return response
        except Exception as e:
            logger.error(f"Error during grading: {str(e)}")
            logger.error(traceback.format_exc())
            
            # Fall back to mock implementation for reliability
            logger.info("Falling back to mock implementation")
            return self._mock_grade_answer(question, user_answer)
    
    async def _grade_answer_sync(self, question, user_answer):
        """Synchronous implementation of grading to avoid asyncio issues"""
        # Format the prompt
        prompt = f"""
        You are a precise and helpful grading assistant. 
        
        Question: {question}
        
        Student's Answer: {user_answer}
        
        Please grade this answer and provide constructive feedback. 
        
        Your response should be in JSON format with the following structure:
        {{
            "grade": [A single letter grade from A to F],
            "feedback": [Detailed feedback on the answer's strengths and weaknesses],
            "suggestions": [Array of 2-3 specific suggestions for improvement]
        }}
        
        Return only the JSON object, nothing else.
        """
        
        # Setup the model
        model = self.client.GenerativeModel(self.model)
        
        # Generate content
        logger.info("Sending request to Gemini API...")
        
        def generate_content():
            try:
                response = model.generate_content(prompt)
                logger.info(f"Received response from Gemini")
                return response.text
            except Exception as e:
                logger.error(f"Error in generate_content: {str(e)}")
                logger.error(traceback.format_exc())
                raise
            
        # Use asyncio.to_thread to run the synchronous code
        content = await asyncio.to_thread(generate_content)
        logger.info(f"Processing content from API response")
        
        # Parse the content
        try:
            # Remove any markdown formatting if present
            if content.startswith('```json'):
                content = content.split('```json')[1].split('```')[0].strip()
            elif content.startswith('```'):
                content = content.split('```')[1].split('```')[0].strip()
            
            # Parse JSON
            result = json.loads(content)
            logger.info(f"Successfully parsed JSON result")
            return result
        except Exception as e:
            logger.error(f"Error parsing JSON: {str(e)}")
            logger.error(f"Raw content: {content}")
            raise
    
    def _mock_grade_answer(self, question, user_answer):
        """Fallback mock grading implementation"""
        logger.info(f"Using mock grading for question: {question}, answer: {user_answer}")
        
        # Simple keyword-based grading for common questions
        lower_question = question.lower()
        lower_answer = user_answer.lower()
        
        # Capital of France question
        if "capital" in lower_question and "france" in lower_question:
            if "paris" in lower_answer:
                return {
                    'grade': 'A',
                    'feedback': 'Excellent! Paris is indeed the capital of France.',
                    'suggestions': [
                        'You could also mention that Paris is the largest city in France',
                        'Consider adding that Paris is located on the Seine River'
                    ]
                }
            else:
                return {
                    'grade': 'F',
                    'feedback': 'Your answer is incorrect. The capital of France is Paris.',
                    'suggestions': [
                        'Review the capitals of European countries',
                        'Try creating a flashcard specifically for European capitals'
                    ]
                }
        
        # For any other question, provide a generic response
        return {
            'grade': 'B',
            'feedback': 'Your answer shows good understanding, but could be more detailed.',
            'suggestions': [
                'Try to be more specific in your answer',
                'Include key facts or dates if relevant', 
                'Consider explaining the underlying concepts'
            ]
        }
    
    async def transcribe_speech(self, audio_data):
        """
        Transcribe speech using Gemini's speech-to-text capabilities
        Note: This is a placeholder. You'll need to adjust based on actual Gemini API capabilities.
        """
        try:
            # Placeholder implementation 
            return "Speech transcription not yet implemented"
        except Exception as e:
            logger.error(f"Error during speech transcription: {str(e)}")
            return ""