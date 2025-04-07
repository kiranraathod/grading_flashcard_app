from fastapi.testclient import TestClient
import pytest
import json
import logging

# Import your FastAPI app
from main import app

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Create the test client
client = TestClient(app)

def test_health_check():
    """Test the health check endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert data["service"] == "flashcard-llm-api"

def test_grade_endpoint():
    """Test the grade endpoint with a simple question"""
    response = client.post(
        "/api/grade",
        json={
            "flashcardId": "test-1",
            "question": "What is the capital of USA?",
            "userAnswer": "Washington DC"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "grade" in data
    assert "feedback" in data
    assert "suggestions" in data
    # If using mock service for test, should get A grade
    assert data["grade"] == "A"
    
def test_invalid_grade_request():
    """Test the grade endpoint with missing fields"""
    response = client.post(
        "/api/grade",
        json={
            "flashcardId": "test-1",
            # Missing question and userAnswer
        }
    )
    assert response.status_code == 422  # FastAPI validation error

def test_get_suggestions():
    """Test getting suggestions for a flashcard"""
    response = client.get("/api/suggestions?flashcardId=test-1")
    assert response.status_code == 200
    data = response.json()
    assert "flashcardId" in data
    assert "suggestions" in data
    assert data["flashcardId"] == "test-1"
    assert isinstance(data["suggestions"], list)

def test_submit_feedback():
    """Test submitting feedback"""
    response = client.post(
        "/api/feedback",
        json={
            "flashcardId": "test-1",
            "userFeedback": "This grading was helpful"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"

if __name__ == "__main__":
    # Run tests manually
    print("Running health check test...")
    test_health_check()
    print("Running grade endpoint test...")
    test_grade_endpoint()
    print("Running get suggestions test...")
    test_get_suggestions()
    print("Running submit feedback test...")
    test_submit_feedback()
    print("All tests passed!")
