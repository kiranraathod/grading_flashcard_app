#!/usr/bin/env python3
"""
Test script to verify the FastAPI grading endpoint is working correctly.
"""

import requests
import json
import sys

def test_grading_endpoint():
    """
    Send a test request to the grading endpoint and print the response.
    """
    print("Testing API endpoint: http://localhost:3000/api/grade")
    
    # Prepare the test data
    test_data = {
        "flashcardId": "1",
        "question": "What is the capital of France?",
        "userAnswer": "Paris"
    }
    
    # Set headers
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        # Send the request
        print(f"Sending test data: {json.dumps(test_data, indent=2)}")
        response = requests.post(
            "http://localhost:3000/api/grade",
            json=test_data,
            headers=headers
        )
        
        # Check the status code
        print(f"Status code: {response.status_code}")
        
        # Print the response
        if response.status_code == 200:
            print("Response:")
            print(json.dumps(response.json(), indent=2))
            print("\n✅ Test passed! The API endpoint is working correctly.")
            return True
        else:
            print(f"Error: {response.text}")
            print("\n❌ Test failed! The API endpoint returned an error.")
            return False
    except Exception as e:
        print(f"Exception occurred: {str(e)}")
        print("\n❌ Test failed! Could not connect to the API endpoint.")
        return False

if __name__ == "__main__":
    success = test_grading_endpoint()
    sys.exit(0 if success else 1)
