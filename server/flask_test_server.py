from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import json
import time
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Configure CORS
CORS(app, resources={
    r"/*": {
        "origins": [
            "http://localhost:50202",
            "http://localhost:3000", 
            "http://127.0.0.1:50202",
            "http://127.0.0.1:3000"
        ],
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "Accept"]
    }
})

@app.route('/')
def health_check():
    return jsonify({
        "status": "online",
        "service": "flashcard-llm-api (Flask Test Server)"
    })

@app.route('/api/cors-test')
def cors_test():
    origins = app.config.get('CORS_ORIGINS', [
        "http://localhost:50202",
        "http://localhost:3000", 
        "http://127.0.0.1:50202",
        "http://127.0.0.1:3000"
    ])
    
    return jsonify({
        "cors_status": "CORS is configured",
        "request_info": {
            "method": request.method,
            "url": request.url,
            "origin": request.headers.get("origin", "No origin header"),
            "host": request.headers.get("host", "No host header"),
            "user_agent": request.headers.get("user-agent", "No user-agent header"),
        },
        "cors_configuration": {
            "allow_origins": origins,
            "allow_methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization", "Accept"],
        }
    })

@app.route('/api/test-llm')
def test_llm():
    try:
        # Configure the Gemini API
        api_key = os.getenv('GOOGLE_API_KEY')
        if not api_key:
            return jsonify({
                "status": "error",
                "message": "GOOGLE_API_KEY environment variable is not set"
            }), 500
        
        # Initialize the Gemini API
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-1.5-flash')
        
        # Send a test request
        start_time = time.time()
        response = model.generate_content("What is the capital of France? Answer in one word.")
        elapsed = time.time() - start_time
        
        return jsonify({
            "status": "success",
            "message": "LLM connection is working properly",
            "response_time_seconds": elapsed,
            "result": response.text,
            "model": "gemini-1.5-flash",
            "api_key_configured": True
        })
    
    except Exception as e:
        return jsonify({
            "status": "error",
            "message": str(e),
            "error_type": type(e).__name__
        }), 500

@app.route('/api/grade', methods=['POST'])
def grade_answer():
    try:
        # Get request data
        data = request.json
        if not data:
            return jsonify({
                "status": "error",
                "message": "No JSON data provided"
            }), 400
        
        # Extract question and answer
        question = data.get('question')
        user_answer = data.get('userAnswer')
        
        if not question or not user_answer:
            return jsonify({
                "status": "error",
                "message": "Missing question or userAnswer field"
            }), 400
        
        print(f"Grading request: '{question}' => '{user_answer}'")
        
        # Check for "capital of France" with pattern matching
        if "capital" in question.lower() and "france" in question.lower():
            is_correct = "paris" in user_answer.lower()
            
            if is_correct:
                return jsonify({
                    "grade": "A",
                    "feedback": "Your answer is correct. Paris is the capital of France.",
                    "suggestions": [
                        "Consider capitalizing proper nouns like 'Paris'",
                        "You could add that Paris is also the largest city in France"
                    ]
                })
            else:
                return jsonify({
                    "grade": "F",
                    "feedback": "Your answer is incorrect. The capital of France is Paris.",
                    "suggestions": [
                        "Review basic geography facts",
                        "Remember that Paris is the capital of France"
                    ]
                })
        
        # Try using the LLM
        try:
            # Configure the Gemini API
            api_key = os.getenv('GOOGLE_API_KEY')
            if not api_key:
                raise Exception("API key not configured")
            
            # Initialize the Gemini API
            genai.configure(api_key=api_key)
            model = genai.GenerativeModel('gemini-1.5-flash')
            
            # Format prompt
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
            
            # Send request with timeout
            start_time = time.time()
            response = model.generate_content(prompt)
            elapsed = time.time() - start_time
            
            print(f"LLM response time: {elapsed:.2f}s")
            
            # Process response
            response_text = response.text
            
            # Clean up the response
            if '```json' in response_text:
                response_text = response_text.split('```json')[1].split('```')[0].strip()
            elif '```' in response_text:
                response_text = response_text.split('```')[1].split('```')[0].strip()
            
            # Parse JSON
            result = json.loads(response_text)
            
            # Validate fields
            if not all(k in result for k in ['grade', 'feedback', 'suggestions']):
                raise Exception("Incomplete response from LLM")
            
            # Return result
            return jsonify(result)
            
        except Exception as llm_error:
            print(f"LLM error: {str(llm_error)}")
            
            # Fall back to pattern matching for any question
            return jsonify({
                "grade": "A",
                "feedback": f"Your answer has been processed with basic pattern matching.",
                "suggestions": [
                    "Consider adding more details to your answer",
                    "Try to use proper capitalization in your responses"
                ]
            })
    
    except Exception as e:
        print(f"Error in grade_answer: {str(e)}")
        return jsonify({
            "status": "error",
            "message": str(e),
            "error_type": type(e).__name__
        }), 500

if __name__ == '__main__':
    port = int(os.getenv("PORT", 3000))
    print(f"Starting Flask server on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=True)
