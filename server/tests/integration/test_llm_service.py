
import asyncio
import logging
import json
from src.services.llm_service import LLMService

# Configure logging
logging.basicConfig(level=logging.DEBUG, 
                  format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def test_llm_service():
    try:
        # Initialize the LLM service
        llm_service = LLMService()
        logger.info("LLM Service initialized")
        
        # Test cases to grade
        test_cases = [
            {"question": "capital of usa", "answer": "ram", "description": "Incorrect USA capital"},
            {"question": "What is the formula for calculating the area of a circle?", "answer": "meter", "description": "Incorrect formula"}
        ]
        
        # Run each test case
        for i, test in enumerate(test_cases):
            logger.info(f"\nTest case {i+1}: {test['description']}")
            logger.info(f"Question: {test['question']}")
            logger.info(f"Answer: {test['answer']}")
            
            # Grade the answer
            result = await llm_service.grade_answer(test['question'], test['answer'])
            
            # Print the result
            logger.info(f"Grading result: {json.dumps(result, indent=2)}")
            
            # Check if it used mock grading
            if result['grade'] == 'B' and result['feedback'] == 'Your answer shows good understanding, but could be more detailed.':
                logger.warning("This appears to be using mock grading!")
            else:
                logger.info("This appears to be using real LLM grading.")
    
    except Exception as e:
        logger.error(f"Error in test script: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())

# Run the test
if __name__ == "__main__":
    asyncio.run(test_llm_service())
