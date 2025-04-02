
import requests
import json
import logging

# Configure logging
logging.basicConfig(level=logging.DEBUG, 
                  format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def test_grading_endpoint():
    """Test the Flask API endpoint for grading"""
    try:
        # Define the API endpoint and test data
        url = "http://localhost:3000/api/grade"
        data = {
            "flashcardId": "test-1",
            "question": "capital of usa",
            "userAnswer": "ram"
        }
        
        logger.info(f"Sending request to {url} with data: {json.dumps(data, indent=2)}")
        
        # Make the API request
        response = requests.post(url, json=data)
        
        # Log response details
        logger.info(f"Response status code: {response.status_code}")
        
        if response.status_code == 200:
            # Parse the response
            result = response.json()
            logger.info(f"Response data: {json.dumps(result, indent=2)}")
            
            # Check if it appears to be mock data
            if result.get('grade') == 'B' and result.get('feedback') == 'Your answer shows good understanding, but could be more detailed.':
                logger.warning("⚠️ This appears to be using mock grading despite the LLM test working!")
            else:
                logger.info("✅ This appears to be using real LLM grading.")
                
            # Compare with correct grade 
            if result.get('grade') != 'F':
                logger.warning("⚠️ The grade should be F for this incorrect answer!")
        else:
            logger.error(f"Error response: {response.text}")
    
    except Exception as e:
        logger.error(f"Error in test script: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())

if __name__ == "__main__":
    test_grading_endpoint()
