
import asyncio
import json
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, 
                  format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Test the LLM grading
async def test_grading():
    try:
        import google.generativeai as genai
        
        # Configure the API key
        genai.configure(api_key='AIzaSyA2VhzYFqn4i2-Vf2gQ2md4zB57kE9vh-E')
        
        # Format the test prompt for grading
        prompt = f"""
        You are a precise and helpful grading assistant. 
        
        Question: capital of usa
        
        Student's Answer: ram
        
        Please grade this answer and provide constructive feedback. 
        
        Your response should be in JSON format with the following structure:
        {{
            "grade": [A single letter grade from A to F],
            "feedback": [Detailed feedback on the answer's strengths and weaknesses],
            "suggestions": [Array of 2-3 specific suggestions for improvement]
        }}
        
        Return only the JSON object, nothing else.
        """
        
        # Set up the model
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        logger.info("Sending request to Gemini API...")
        response = model.generate_content(prompt)
        
        content = response.text
        logger.info(f"Raw response: {content}")
        
        # Try to parse JSON
        try:
            # Remove any markdown formatting if present
            if content.startswith('```json'):
                content = content.split('```json')[1].split('```')[0].strip()
            elif content.startswith('```'):
                content = content.split('```')[1].split('```')[0].strip()
            
            # Parse JSON
            result = json.loads(content)
            logger.info(f"Parsed JSON: {json.dumps(result, indent=2)}")
            return result
        except Exception as e:
            logger.error(f"Error parsing JSON: {str(e)}")
            logger.error(f"Raw content: {content}")
            raise

    except Exception as e:
        logger.error(f"Error during grading test: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())

# Run the test
if __name__ == "__main__":
    asyncio.run(test_grading())
