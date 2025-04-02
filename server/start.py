import uvicorn
import os
from dotenv import load_dotenv
import sys
import logging

# Configure basic logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

if __name__ == "__main__":
    port = int(os.getenv("PORT", 3000))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    print("======================================")
    print("🚀 Starting Flashcard Grading API")
    print("======================================")
    print(f"📡 Listening on port: {port}")
    print(f"🐛 Debug mode: {debug}")
    print("📔 API documentation available at:")
    print(f"   - http://localhost:{port}/docs")
    print(f"   - http://localhost:{port}/redoc")
    print("======================================")
    
    # Print all registered routes before starting the server
    try:
        # Importing here to avoid circular imports
        from main import app
        
        print("\n🛣️  REGISTERED ROUTES:")
        for route in app.routes:
            print(f"  {route.methods} {route.path}")
        print("======================================\n")
    except Exception as e:
        print(f"Error listing routes: {e}")
    
    # Set higher log level to see more details
    uvicorn.run(
        "main:app", 
        host="0.0.0.0", 
        port=port, 
        reload=debug,
        log_level="debug"  # Changed from info to debug
    )
