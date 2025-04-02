from dotenv import load_dotenv
import os
import json
import asyncio
import logging
import traceback
import sys
import time
from fastapi import HTTPException, status

# Load environment variables
load_dotenv()

# Set up logger
logging.basicConfig(level=logging.DEBUG, handlers=[logging.StreamHandler(sys.stdout)])
logger = logging.getLogger(__name__)

class LLMService:
    def __init__(self):
        self.model = os.getenv('LLM_MODEL', 'gemini-1.5-flash')
        self._init_client()
        logger.debug(f"LLMService initialized with model: {self.model}")

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
            
            # Test connection immediately to verify API key and model
            try:
                model = self.client.GenerativeModel(self.model)
                logger.info("Successfully initialized model object")
            except Exception as e:
                logger.error(f"Failed to initialize model: {str(e)}")
                raise
                
        except ImportError as e:
            logger.error(f"Failed to import google.generativeai. Make sure it's installed: {e}")
            raise
        except Exception as e:
            logger.error(f"Error initializing Google Gemini client: {str(e)}")
            logger.error(traceback.format_exc())
            raise
    
    async def grade_answer(self, question, user_answer):
        """Grade the user's answer using Gemini - Improved timeout handling"""
        logger.info(f"🤖 LLM grading: '{question}' => '{user_answer}'")
        start_time = time.time()
        
        try:
            # Increased timeout to 10 seconds to allow the LLM more time to respond
            logger.info("🤖 Starting LLM request with 10 second timeout")
            
            response = await asyncio.wait_for(
                self._grade_answer_sync(question, user_answer),
                timeout=10.0  # Longer timeout for better LLM results
            )
            
            elapsed = time.time() - start_time
            logger.info(f"🤖 LLM completed in {elapsed:.2f}s: {response}")
            return response
            
        except asyncio.TimeoutError:
            elapsed = time.time() - start_time
            logger.warning(f"🤖 LLM timed out after {elapsed:.2f}s")
            
            # Return timeout error
            return {
                'grade': 'N/A',
                'feedback': 'The AI grading service timed out. Please try again.',
                'suggestions': [
                    'Try again in a few moments',
                    'The system may be experiencing high load'
                ]
            }
            
        except Exception as e:
            elapsed = time.time() - start_time
            logger.error(f"🤖 LLM error after {elapsed:.2f}s: {str(e)}")
            logger.error(traceback.format_exc())
            
            # Return a helpful error response
            return {
                'grade': 'N/A',
                'feedback': f'Error occurred while processing your answer: {str(e)}',
                'suggestions': [
                    'Please try again',
                    'The grading service may be temporarily unavailable'
                ]
            }
    
    async def _grade_answer_sync(self, question, user_answer):
        """Direct implementation of grading using only the LLM with no pattern matching"""
        logger.info("🤖 Starting _grade_answer_sync method")
        
        # Format a clear prompt for accurate grading
        prompt = f"""
        You are a fair grading assistant. Evaluate the student's answer.
        
        Question: {question}
        Student's Answer: {user_answer}
        
        Respond with ONLY a JSON object in this exact format:
        {{
            "grade": "[Letter grade A-F]",
            "feedback": "[Brief 1-2 sentence feedback]",
            "suggestions": ["[Suggestion 1]", "[Suggestion 2]"]
        }}
        
        The response must be properly formatted JSON only.
        """
        
        logger.info("🤖 Prompt prepared for LLM")
        
        # Setup the model with a try/except
        try:
            model = self.client.GenerativeModel(self.model)
        except Exception as e:
            logger.error(f"🤖 Model initialization error: {str(e)}")
            raise Exception(f"Failed to initialize LLM model: {str(e)}")
        
        # Generate content with the LLM
        try:
            logger.info("🤖 Sending request to API")
            start_time = time.time()
            
            # Define request options with explicit timeout
            request_options = {"timeout": 9.0}  # 9 seconds explicit timeout for API call
            logger.info("🤖 Setting explicit Gemini API timeout of 9 seconds")
            
            try:
                # Based on our test script, we know this works with the current API key
                response_text = await asyncio.to_thread(
                    lambda: model.generate_content(
                        prompt,
                        generation_config={
                            "temperature": 0.1,  # Low temperature for more consistent outputs
                            "max_output_tokens": 150,  # Reduced token count
                        },
                        request_options=request_options  # Pass explicit timeout to API
                    ).text
                )
                
                elapsed = time.time() - start_time
                logger.info(f"🤖 API responded in {elapsed:.2f}s")
                
            except asyncio.TimeoutError:
                elapsed = time.time() - start_time
                logger.error(f"🤖 Google Gemini API call timed out after {elapsed:.2f}s")
                raise HTTPException(
                    status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                    detail="LLM API request timed out"
                )
            
            except Exception as api_error:
                elapsed = time.time() - start_time
                logger.error(f"🤖 Google Gemini API error after {elapsed:.2f}s: {str(api_error)}")
                
                # Check for specific Google API errors
                error_message = str(api_error).lower()
                if "deadline exceeded" in error_message or "timeout" in error_message:
                    logger.error("🤖 Gemini API deadline exceeded or timeout detected")
                    raise HTTPException(
                        status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                        detail="LLM API request timed out"
                    )
                elif "rate limit" in error_message or "quota" in error_message:
                    logger.error("🤖 Gemini API rate limit or quota exceeded")
                    raise HTTPException(
                        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                        detail="LLM API rate limit exceeded"
                    )
                else:
                    # Re-raise other API errors to be caught by outer block
                    raise
            
            # Parse response with error handling
            try:
                # Clean up the response for reliable parsing
                if '```json' in response_text:
                    response_text = response_text.split('```json')[1].split('```')[0].strip()
                elif '```' in response_text:
                    response_text = response_text.split('```')[1].split('```')[0].strip()
                
                # Parse the JSON
                result = json.loads(response_text)
                
                # Validate the result has all required fields
                if not all(k in result for k in ['grade', 'feedback', 'suggestions']):
                    logger.warning("🤖 Missing fields in response, raising exception")
                    raise Exception("Incomplete response from LLM")
                
                return result
                
            except json.JSONDecodeError as e:
                logger.error(f"🤖 JSON parsing error: {str(e)}, raw: {response_text[:100]}...")
                raise Exception(f"Failed to parse LLM response as JSON: {str(e)}")
                
        except Exception as e:
            logger.error(f"🤖 API request error: {str(e)}")
            raise Exception(f"Error during LLM grading: {str(e)}")
    
    # Mock grading method removed
    
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