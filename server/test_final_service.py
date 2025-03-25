
import asyncio
import json
from src.services.llm_service_final import LLMService

async def test_service():
    """Test the improved LLM service with the problematic example"""
    service = LLMService()
    
    # Test cases
    test_cases = [
        {
            "question": "What is the formula for calculating the area of a circle?",
            "user_answer": "meter",
            "description": "Unit instead of formula (from screenshot)"
        },
        {
            "question": "What is the formula for calculating the area of a circle?",
            "user_answer": "pi r squared",
            "description": "Correct answer in words"
        },
        {
            "question": "What is the formula for calculating the area of a circle?",
            "user_answer": "A = pi*r^2",
            "description": "Correct formula with ASCII symbols"
        }
    ]
    
    for i, test in enumerate(test_cases):
        print(f"\n\nTest case {i+1}: {test['description']}")
        print(f"Question: {test['question']}")
        print(f"User answer: {test['user_answer']}")
        
        try:
            # Grade the answer
            print("\nAttempting to grade with LLM...")
            result = await service.grade_answer(test['question'], test['user_answer'])
            
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
