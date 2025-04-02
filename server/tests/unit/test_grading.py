
import os
import json
from dotenv import load_dotenv
import google.generativeai as genai

# Load environment variables
load_dotenv()

# Configure the Gemini API
api_key = os.getenv('GOOGLE_API_KEY')
model_name = os.getenv('LLM_MODEL', 'gemini-2.0-flash')

print(f"Using API key: {api_key[:5]}...{api_key[-5:]}")
print(f"Using model: {model_name}")

# Configure the client
genai.configure(api_key=api_key)

def grade_answer(question, user_answer):
    """Test the grading function with a specific question and answer"""
    
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
    model = genai.GenerativeModel(model_name)
    
    # Generate content
    print("Sending request to Gemini API...")
    response = model.generate_content(prompt)
    
    # Process the content
    content = response.text
    print("\nRaw API response:")
    print(content)
    print()
    
    # Parse JSON
    try:
        # Remove any markdown formatting if present
        if content.startswith('```json'):
            content = content.split('```json')[1].split('```')[0].strip()
        elif content.startswith('```'):
            content = content.split('```')[1].split('```')[0].strip()
        
        # Parse JSON
        result = json.loads(content)
        return result
    except Exception as e:
        print(f"Error parsing JSON: {str(e)}")
        print(f"Raw content: {content}")
        return {
            'grade': 'E',
            'feedback': 'Error in grading system',
            'suggestions': ['Please try again']
        }

# Test with the example from the screenshot
question = "What is the formula for calculating the area of a circle?"
user_answer = "meter"

print(f"Testing with:")
print(f"Question: {question}")
print(f"User answer: {user_answer}")
print()

result = grade_answer(question, user_answer)
print("\nGrading result:")
print(json.dumps(result, indent=2))
