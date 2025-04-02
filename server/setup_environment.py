import subprocess
import sys
import os
import platform

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_colored(text, color):
    """Print colored text if the platform supports it."""
    if platform.system() != 'Windows' or 'TERM' in os.environ:
        print(f"{color}{text}{Colors.RESET}")
    else:
        print(text)

def run_command(command):
    """Run a command and return the result."""
    try:
        result = subprocess.run(command, shell=True, check=True, text=True, 
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr

def main():
    print_colored("=== Flashcard Grading App Server Environment Setup ===", Colors.BOLD)
    
    # Check Python version
    python_version = platform.python_version()
    print(f"Python version: {python_version}")
    
    # Check pip version
    success, output = run_command(f"{sys.executable} -m pip --version")
    if success:
        print(f"Pip version: {output.strip()}")
    else:
        print_colored("pip not found or not working properly", Colors.RED)
        return
    
    # Install dependencies
    print_colored("\nInstalling dependencies from requirements.txt...", Colors.YELLOW)
    success, output = run_command(f"{sys.executable} -m pip install -r requirements.txt")
    
    if success:
        print_colored("Successfully installed dependencies!", Colors.GREEN)
    else:
        print_colored("Failed to install dependencies:", Colors.RED)
        print(output)
        return
    
    # Verify key packages
    print_colored("\nVerifying installations:", Colors.YELLOW)
    packages = ['fastapi', 'flask', 'uvicorn', 'google.generativeai']
    
    for package in packages:
        module_name = package.split('.')[0]
        success, _ = run_command(f"{sys.executable} -c \"import {module_name}; print('{module_name} is installed')\"")
        
        if success:
            print_colored(f"✓ {package} is installed", Colors.GREEN)
        else:
            print_colored(f"✗ {package} is NOT installed properly", Colors.RED)
    
    print_colored("\n=== Setup Complete ===", Colors.BOLD)
    print("\nTo run the FastAPI server: python -m uvicorn main:app --reload")
    print("To run the Flask server: python flask_test_server.py")
    print("To run the simple server: python simple_test_server.py")

if __name__ == "__main__":
    main()
