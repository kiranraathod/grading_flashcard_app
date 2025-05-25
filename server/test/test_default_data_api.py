"""Simple test for Default Data API endpoints - Task 5.1 validation"""
import sys, os
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import create_app

def test_all_endpoints():
    app, client = create_app(), TestClient(create_app())
    print("Testing Default Data API endpoints...")
    
    # Test all 6 endpoints
    endpoints = [
        ("/api/default-data/health", "health"),
        ("/api/default-data/categories", "categories"),
        ("/api/default-data/flashcard-sets", "flashcard-sets"),
        ("/api/default-data/interview-questions", "interview-questions"),
        ("/api/default-data/category-counts", "category-counts"),
        ("/api/default-data/", "combined-data")
    ]
    
    for endpoint, name in endpoints:
        response = client.get(endpoint)
        assert response.status_code == 200, f"{name} failed with {response.status_code}"
        data = response.json()
        
        if name == "health":
            assert data["status"] == "healthy"
        elif name in ["categories", "flashcard-sets", "interview-questions"]:
            assert isinstance(data, list) and len(data) > 0
        elif name == "category-counts":
            assert "counts" in data and "total_questions" in data
        elif name == "combined-data":
            required = ["flashcard_sets", "interview_questions", "categories", "category_counts"]
            assert all(key in data for key in required)
        
        print(f"[PASS] {name}")
    
    print("\n[SUCCESS] All 6 endpoints working! Task 5.1 implementation validated.")

if __name__ == "__main__":
    try:
        test_all_endpoints()
    except Exception as e:
        print(f"[FAIL] {e}")
        sys.exit(1)
