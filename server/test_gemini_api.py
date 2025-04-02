#!/usr/bin/env python
import os
import sys
import time
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the API key from environment
api_key = os.getenv('GOOGLE_API_KEY')
if not api_key:
    print("ERROR: GOOGLE_API_KEY environment variable is not set")
    print("Please check your .env file or set it manually")
    sys.exit(1)

print(f"Found API key: {api_key[:4]}...{api_key[-4:]}")

try:
    # Import Google's generative AI library
    print("Importing Google Generative AI library...")
    import google.generativeai as genai
    print("Successfully imported google.generativeai")
except ImportError:
    print("ERROR: Failed to import google.generativeai")
    print("Try installing it with: pip install -q -U google-generativeai")
    sys.exit(1)

# Configure the library with your API key
print(f"Configuring genai with API key...")
genai.configure(api_key=api_key)

# List of models to try
models_to_test = [
    "gemini-1.5-flash",  # Your current model
    "gemini-1.0-pro",    # Fallback model 1
    "gemini-pro"         # Fallback model 2
]

# Test each model
for model_name in models_to_test:
    print(f"\n\n----- Testing model: {model_name} -----")
    try:
        print(f"Initializing model...")
        model = genai.GenerativeModel(model_name)
        
        print(f"Sending test request...")
        start_time = time.time()
        
        response = model.generate_content(
            "What is the capital of France? Answer in one word."
        )
        
        elapsed = time.time() - start_time
        print(f"SUCCESS! Model {model_name} responded in {elapsed:.2f} seconds")
        print(f"Response: {response.text}")
        
    except Exception as e:
        print(f"ERROR with model {model_name}: {str(e)}")
        
print("\n\nTest completed. Check the results above to determine which models work with your API key.")
print("If no models work, your API key might be invalid or you may not have access to Gemini API.")
