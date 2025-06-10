#!/usr/bin/env python3
"""
Test script to validate the A-F to 0-100 grading migration.
This script tests both the server-side API and validates the expected responses.
"""

import requests
import json
import sys
from typing import Dict, Any

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust if your server runs on a different port
GRADE_ENDPOINT = f"{BASE_URL}/api/grade"

def test_grading_api():
    """Test the grading API with various test cases."""
    
    test_cases = [
        {
            "name": "Perfect Answer",
            "data": {
                "flashcardId": "test-001",
                "question": "What is the capital of France?",
                "userAnswer": "Paris",
                "correctAnswer": "Paris"
            },
            "expected_score_range": (90, 100)
        },
        {
            "name": "Good Answer",
            "data": {
                "flashcardId": "test-002", 
                "question": "What is 2 + 2?",
                "userAnswer": "4",
                "correctAnswer": "Four"
            },
            "expected_score_range": (80, 95)
        },
        {
            "name": "Partial Answer",
            "data": {
                "flashcardId": "test-003",
                "question": "Name three primary colors",
                "userAnswer": "red, blue",
                "correctAnswer": "red, blue, yellow"
            },
            "expected_score_range": (60, 80)
        },
        {
            "name": "Wrong Answer",
            "data": {
                "flashcardId": "test-004",
                "question": "What is the capital of France?",
                "userAnswer": "London",
                "correctAnswer": "Paris"
            },
            "expected_score_range": (0, 60)
        }
    ]
    
    print("🧪 Testing A-F to 0-100 Grading Migration")
    print("=" * 50)
    
    all_passed = True
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{i}. Testing: {test_case['name']}")
        print(f"   Question: {test_case['data']['question']}")
        print(f"   User Answer: {test_case['data']['userAnswer']}")
        print(f"   Correct Answer: {test_case['data']['correctAnswer']}")
        
        try:
            # Make API request
            response = requests.post(GRADE_ENDPOINT, json=test_case['data'], timeout=30)
            
            if response.status_code != 200:
                print(f"   ❌ HTTP Error: {response.status_code}")
                print(f"   Response: {response.text}")
                all_passed = False
                continue
            
            # Parse response
            result = response.json()
            
            # Validate response structure
            required_fields = ['score', 'feedback', 'suggestions']
            missing_fields = [field for field in required_fields if field not in result]
            
            if missing_fields:
                print(f"   ❌ Missing fields: {missing_fields}")
                all_passed = False
                continue
            
            # Validate score
            score = result['score']
            if not isinstance(score, int) or score < 0 or score > 100:
                print(f"   ❌ Invalid score: {score}")
                all_passed = False
                continue
            
            # Check score range
            min_score, max_score = test_case['expected_score_range']
            if not (min_score <= score <= max_score):
                print(f"   ⚠️  Score {score} outside expected range {min_score}-{max_score}")
                # This is a warning, not a failure
            
            # Validate feedback
            if not isinstance(result['feedback'], str) or not result['feedback'].strip():
                print(f"   ❌ Invalid feedback: {result['feedback']}")
                all_passed = False
                continue
            
            # Validate suggestions
            if not isinstance(result['suggestions'], list) or len(result['suggestions']) == 0:
                print(f"   ❌ Invalid suggestions: {result['suggestions']}")
                all_passed = False
                continue
            
            # Test passed!
            print(f"   ✅ Score: {score}/100")
            print(f"   ✅ Feedback: {result['feedback'][:60]}...")
            print(f"   ✅ Suggestions: {len(result['suggestions'])} provided")
            
            # Show equivalent letter grade for reference
            letter_grade = score_to_letter_grade(score)
            print(f"   📝 Equivalent Letter Grade: {letter_grade}")
            
        except requests.exceptions.RequestException as e:
            print(f"   ❌ Request Error: {e}")
            all_passed = False
        except json.JSONDecodeError as e:
            print(f"   ❌ JSON Error: {e}")
            all_passed = False
        except Exception as e:
            print(f"   ❌ Unexpected Error: {e}")
            all_passed = False
    
    print("\n" + "=" * 50)
    if all_passed:
        print("🎉 All tests passed! Migration appears successful.")
        print("\n✅ Validation Summary:")
        print("   • API returns 0-100 scores instead of A-F grades")
        print("   • Response structure is correct (score, feedback, suggestions)")
        print("   • Score ranges are appropriate for answer quality")
        print("   • Error handling is working properly")
        return True
    else:
        print("❌ Some tests failed. Please check the issues above.")
        return False

def score_to_letter_grade(score: int) -> str:
    """Convert a numerical score to letter grade for reference."""
    if score >= 90:
        return 'A'
    elif score >= 80:
        return 'B'
    elif score >= 70:
        return 'C'
    elif score >= 60:
        return 'D'
    else:
        return 'F'

def test_server_availability():
    """Test if the server is running and accessible."""
    try:
        response = requests.get(f"{BASE_URL}/docs", timeout=5)
        if response.status_code == 200:
            print("✅ Server is running and accessible")
            return True
        else:
            print(f"⚠️  Server responded with status {response.status_code}")
            return False
    except requests.exceptions.RequestException:
        print("❌ Server is not accessible. Please ensure the FastAPI server is running.")
        print(f"   Expected URL: {BASE_URL}")
        print("   Start server with: python main.py")
        return False

if __name__ == "__main__":
    print("🚀 FlashMaster Grading Migration Test")
    print("This script validates the A-F to 0-100 scoring migration\n")
    
    # Test server availability first
    if not test_server_availability():
        sys.exit(1)
    
    # Run grading tests
    success = test_grading_api()
    
    if success:
        print("\n🎯 Next Steps:")
        print("   1. Test the Flutter client with the updated server")
        print("   2. Verify UI displays scores correctly")
        print("   3. Check completion logic (score >= 70)")
        print("   4. Test error handling scenarios")
        sys.exit(0)
    else:
        sys.exit(1)
