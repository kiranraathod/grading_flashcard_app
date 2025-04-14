"""
Simple test script to verify that the ping endpoint works correctly.
"""
import requests
import sys

def test_ping_endpoint():
    """Test the ping endpoint to ensure it's accessible."""
    try:
        response = requests.get('http://localhost:3000/api/ping')
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 200:
            print("✅ Ping endpoint is working correctly!")
            return True
        else:
            print("❌ Ping endpoint returned a non-200 status code.")
            return False
    except Exception as e:
        print(f"❌ Error connecting to ping endpoint: {e}")
        return False

if __name__ == "__main__":
    print("Testing ping endpoint...")
    success = test_ping_endpoint()
    if not success:
        sys.exit(1)
