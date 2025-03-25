
import asyncio
import json
from src.services.llm_service import LLMService

async def test_service():
    """Test the LLM service with the India example"""
    service = LLMService()
    
    # Test case from new screenshot
    question = "India"
    user_answer = "mumbai"
    correct_answer = "delhi"
    
    print(f"Testing with:")
    print(f"Question: {question}")
    print(f"User answer: {user_answer}")
    print(f"Correct answer: {correct_answer}")
    
    try:
        # Grade the answer
        print("\nAttempting to grade with LLM...")
        result = await service.grade_answer(question, user_answer)
        
        # Print the result
        print("\nGrading result:")
        print(f"Grade: {result['grade']}")
        print(f"Feedback: {result['feedback']}")
        print("Suggestions:")
        for suggestion in result['suggestions']:
            print(f"- {suggestion}")
    except Exception as e:
        print(f"Error during testing: {str(e)}")

# Run the test
if __name__ == "__main__":
    asyncio.run(test_service())
