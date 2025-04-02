#!/usr/bin/env python3
"""
Supabase Environment Setup Script

This script helps set up the environment variables needed for Supabase integration.
It updates the .env file with the provided Supabase credentials.
"""

import os
import re
import argparse
from pathlib import Path

def update_env_file(supabase_url, supabase_key, supabase_jwt_secret):
    """
    Update the .env file with Supabase credentials
    
    Args:
        supabase_url (str): The Supabase project URL
        supabase_key (str): The Supabase API key (anon key)
        supabase_jwt_secret (str): The JWT secret for token verification
    """
    env_path = Path(__file__).parent.parent / '.env'
    
    if not env_path.exists():
        print(f"Error: .env file not found at {env_path}")
        return False
    
    with open(env_path, 'r') as file:
        env_content = file.read()
    
    # Replace existing variables or add new ones
    patterns = {
        'SUPABASE_URL': r'SUPABASE_URL=.*',
        'SUPABASE_KEY': r'SUPABASE_KEY=.*',
        'SUPABASE_JWT_SECRET': r'SUPABASE_JWT_SECRET=.*'
    }
    
    replacements = {
        'SUPABASE_URL': f'SUPABASE_URL={supabase_url}',
        'SUPABASE_KEY': f'SUPABASE_KEY={supabase_key}',
        'SUPABASE_JWT_SECRET': f'SUPABASE_JWT_SECRET={supabase_jwt_secret}'
    }
    
    for var, pattern in patterns.items():
        replacement = replacements[var]
        if re.search(pattern, env_content):
            env_content = re.sub(pattern, replacement, env_content)
        else:
            env_content += f"\n{replacement}"
    
    with open(env_path, 'w') as file:
        file.write(env_content)
    
    print(f"Updated .env file with Supabase credentials at {env_path}")
    return True

def main():
    parser = argparse.ArgumentParser(description="Setup Supabase environment variables")
    
    parser.add_argument("--url", required=True, help="Supabase project URL")
    parser.add_argument("--key", required=True, help="Supabase API key (anon key)")
    parser.add_argument("--jwt", required=True, help="Supabase JWT secret")
    
    args = parser.parse_args()
    
    success = update_env_file(args.url, args.key, args.jwt)
    
    if success:
        print("Environment variables set up successfully!")
        print("You can now start your FastAPI application.")
    else:
        print("Failed to set up environment variables.")

if __name__ == "__main__":
    main()
