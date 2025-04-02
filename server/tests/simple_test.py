
from dotenv import load_dotenv
import os
import json
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, 
                   format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

def test_gemini_api():
    """Simple test of the Gemini API connection"""
    try:
        # Import the Google Generative AI package
        import google.generativeai as genai
        
        # Get API key from environment variables
        api_key = os.getenv('GOOGLE_API_KEY')
        model_name = os.getenv('LLM_MODEL', 'gemini-2.0-flash')
        
        if not api_key:
            logger.error("❌ GOOGLE_API_KEY not found in environment variables!")
            return False
            
        logger.info(f"🔑 Using API key: {api_key[:5]}...{api_key[-5:]}")
        logger.info(f"🤖 Using model: {model_name}")
        
        # Configure the client
        genai.configure(api_key=api_key)
        
        # Create a simple prompt
        prompt = "What is 2+2? Respond with just the number."
        
        # Initialize the model
        logger.info(f"Initializing model: {model_name}")
        model = genai.GenerativeModel(model_name)
        
        # Generate content
        logger.info("Sending request to Gemini API...")
        response = model.generate_content(prompt)
        
        # Get and print the response
        content = response.text
        logger.info(f"Response: {content}")
        
        # Check if the response is as expected
        if '4' in content:
            logger.info("✅ API connection successful!")
            return True
        else:
            logger.warning(f"⚠️ Unexpected response from API: {content}")
            return False
            
    except Exception as e:
        logger.error(f"❌ Error testing Gemini API: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        return False

if __name__ == "__main__":
    logger.info("🧪 Testing Google Gemini API connection...")
    success = test_gemini_api()
    
    if success:
        logger.info("✅ Test completed successfully!")
    else:
        logger.error("❌ Test failed! Check the logs for details.")
