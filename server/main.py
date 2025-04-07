from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
import os
import logging
import sys
import json
from dotenv import load_dotenv

# Import the router
from src.routes.grading_routes import router as grading_router

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Set log levels for specific modules
logging.getLogger('src.services.llm_service').setLevel(logging.DEBUG)
logging.getLogger('src.routes.grading_routes').setLevel(logging.DEBUG)

# Load environment variables
load_dotenv()

def create_app():
    app = FastAPI(
        title="Flashcard Grading API",
        description="API for grading flashcard answers using Google's Gemini LLM",
        version="1.0.0"
    )
    
    # For development: Allow all origins to fix CORS issues with web client
    # In production, you would restrict this to specific origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # Allow all origins for development
        allow_credentials=True,
        allow_methods=["*"],  # Allow all methods
        allow_headers=["*"],  # Allow all headers
        expose_headers=["*"],  # Expose all headers
    )

    # Add middleware for request/response logging
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        logger.debug(f'Request path: {request.url.path}')
        logger.debug('Request Headers: %s', dict(request.headers))
        
        # Process the request and get response
        response = await call_next(request)
        
        logger.debug('Response Status: %s', response.status_code)
        logger.debug('Response Headers: %s', dict(response.headers))
        return response
    
    # Register routers
    app.include_router(grading_router, prefix="/api")
    
    @app.get("/")
    def health_check():
        return {'status': 'online', 'service': 'flashcard-llm-api'}
    
    return app

app = create_app()

if __name__ == '__main__':
    import uvicorn
    
    debug = True if os.getenv('DEBUG', 'True').lower() == 'true' else False
    port = int(os.getenv('PORT', 3000))  # Default to 3000 to match client expectation
    
    logger.info(f"Starting server on port {port} with debug={debug}")
    
    # Run with Uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=debug)
