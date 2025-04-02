#!/usr/bin/env python3
"""
Supabase Connection Test Script

This script tests the connection to Supabase and verifies that the credentials are working.
It also checks if the required tables exist in the database.
"""

import os
import sys
from dotenv import load_dotenv
from supabase import create_client

# Add parent directory to path to import from src
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_supabase_connection():
    """Test the connection to Supabase"""
    
    # Load environment variables
    load_dotenv()
    
    # Get Supabase credentials
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    
    if not url or not key:
        print("Error: Supabase URL or key not found in environment variables")
        print("Please run the setup_supabase_env.py script first")
        return False
    
    try:
        # Initialize Supabase client
        print(f"Connecting to Supabase at {url}...")
        client = create_client(url, key)
        
        # Test connection with a simple query
        print("Testing connection...")
        response = client.table("profiles").select("count", count="exact").execute()
        
        print(f"Connection successful! Found {response.count} profiles.")
        
        # Check if all required tables exist
        required_tables = [
            "profiles",
            "flashcards",
            "flashcard_grades",
            "user_feedback",
            "user_progress",
            "study_sessions"
        ]
        
        print("\nChecking for required tables:")
        
        for table in required_tables:
            try:
                response = client.table(table).select("count", count="exact").limit(1).execute()
                print(f"✓ Table '{table}' exists with {response.count} rows")
            except Exception as e:
                print(f"✗ Table '{table}' does not exist or is not accessible: {str(e)}")
                print("  Make sure to run the schema.sql script in the Supabase SQL Editor")
        
        return True
    
    except Exception as e:
        print(f"Error connecting to Supabase: {str(e)}")
        print("Please check your credentials and make sure your IP is allowed")
        return False

if __name__ == "__main__":
    success = test_supabase_connection()
    
    if success:
        print("\nAll tests passed! Supabase connection is working correctly.")
    else:
        print("\nSome tests failed. Please check the error messages above.")
