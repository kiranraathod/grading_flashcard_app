#!/usr/bin/env python3
"""
Quick validation script for Task 2.2 implementation
"""
import sys
import os

def test_imports():
    """Test if all required modules can be imported."""
    print("Testing imports...")
    
    try:
        # Test FastAPI
        import fastapi
        print("SUCCESS: FastAPI imported successfully")
        
        # Test Supabase
        import supabase
        print("SUCCESS: Supabase imported successfully")
        
        # Test our modules
        sys.path.append('server/src')
        from services.database_service import db_service
        print("SUCCESS: Database service imported successfully")
        
        from routes.database_routes import router
        print("SUCCESS: Database routes imported successfully")
        
        return True
        
    except ImportError as e:
        print(f"ERROR: Import error: {e}")
        return False

def test_environment():
    """Test environment configuration."""
    print("\nTesting environment configuration...")
    
    # Load environment
    try:
        from dotenv import load_dotenv
        # Try to load from server directory
        if os.path.exists('server/.env'):
            load_dotenv('server/.env')
            print("SUCCESS: Environment loaded from server/.env file")
        else:
            print("WARNING: server/.env file not found")
    except:
        print("WARNING: Could not load .env file")
    
    required_vars = ['SUPABASE_URL', 'SUPABASE_ANON_KEY']
    missing_vars = []
    
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"SUCCESS: {var} is set")
        else:
            print(f"ERROR: {var} is not set")
            missing_vars.append(var)
    
    return len(missing_vars) == 0

def test_database_service():
    """Test database service initialization."""
    print("\nTesting database service...")
    
    try:
        sys.path.append('server/src')
        from services.database_service import db_service
        
        if db_service.supabase:
            print("SUCCESS: Database service initialized successfully")
            print(f"SUCCESS: Supabase URL configured")
            return True
        else:
            print("ERROR: Database service not initialized")
            return False
            
    except Exception as e:
        print(f"ERROR: Database service error: {e}")
        return False

def main():
    """Run all validation tests."""
    print("Task 2.2 Implementation Validation")
    print("=" * 50)
    
    tests = [
        ("Import Tests", test_imports),
        ("Environment Tests", test_environment),
        ("Database Service Tests", test_database_service)
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\nRunning {test_name}...")
        try:
            result = test_func()
            results.append(result)
            status = "PASSED" if result else "FAILED"
            print(f"{test_name}: {status}")
        except Exception as e:
            print(f"{test_name}: ERROR - {e}")
            results.append(False)
    
    # Summary
    print("\n" + "=" * 50)
    print("VALIDATION SUMMARY")
    print("=" * 50)
    
    passed = sum(results)
    total = len(results)
    
    print(f"Tests Passed: {passed}/{total}")
    print(f"Success Rate: {(passed/total)*100:.1f}%")
    
    if passed == total:
        print("SUCCESS: ALL TESTS PASSED - Ready for deployment!")
        return 0
    else:
        print("WARNING: Some tests failed - check issues above")
        return 1

if __name__ == "__main__":
    sys.exit(main())
