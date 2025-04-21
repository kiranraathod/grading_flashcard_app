"""
Main application entry point for the Flashcard Grading API.
"""
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
import os
import logging
import logging.config
import sys
import json
from fastapi.responses import JSONResponse

# Import the routers
from src.routes.grading_routes import router as grading_router
from src.routes.interview_routes import router as interview_router
from src.utils.exceptions import BaseFlashcardAPIError
from src.config.config import config

# Configure logging
logging.config.dictConfig(config.get_logging_config())
logger = logging.getLogger(__name__)

def create_app():
    """Create and configure the FastAPI application."""
    
    # Validate configuration before starting
    config_error = config.validate_config()
    if config_error:
        logger.error(f"Configuration error: {config_error}")
        # Continue with warning since we can use fallback grading
        logger.warning("⚠️ Starting with limited functionality due to configuration error")
    
    app = FastAPI(
        title="Flashcard Grading API",
        description="API for grading flashcard answers using Google's Gemini LLM",
        version="1.0.0",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json"
    )
    
    # Configure CORS based on settings
    app.add_middleware(
        CORSMiddleware,
        allow_origins=config.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],  # Can be restricted in production
        allow_headers=["*"],  # Can be restricted in production
        expose_headers=["*"],  # Can be restricted in production
    )

    # Add middleware for request/response logging
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        """Log request and response details."""
        request_id = request.headers.get('X-Request-ID', 'unknown')
        logger.debug(f'[{request_id}] Request path: {request.url.path}')
        
        # Log request headers at debug level
        if logger.isEnabledFor(logging.DEBUG):
            logger.debug(f'[{request_id}] Request Headers: {dict(request.headers)}')
        
        # Process the request and get response
        try:
            response = await call_next(request)
            logger.debug(f'[{request_id}] Response Status: {response.status_code}')
            
            # Log response headers at debug level
            if logger.isEnabledFor(logging.DEBUG):
                logger.debug(f'[{request_id}] Response Headers: {dict(response.headers)}')
                
            return response
        except Exception as e:
            logger.error(f'[{request_id}] Unhandled error during request processing: {str(e)}')
            return JSONResponse(
                status_code=500,
                content={"detail": "Internal server error"}
            )
    
    # Add exception handler for our custom exceptions
    @app.exception_handler(BaseFlashcardAPIError)
    async def handle_api_error(request: Request, exc: BaseFlashcardAPIError):
        """Handle custom API exceptions."""
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.message}
        )
    
    # Register routers
    app.include_router(grading_router, prefix="/api")
    app.include_router(interview_router, prefix="/api")
    
    @app.get("/")
    def health_check():
        """Basic health check endpoint."""
        return {
            'status': 'online', 
            'service': 'flashcard-llm-api',
            'version': '1.0.0'
        }
    
    @app.get("/api/health")
    def api_health_check():
        """Detailed health check for the API."""
        return {
            'status': 'online',
            'service': 'flashcard-llm-api',
            'version': '1.0.0',
            'config_valid': config_error is None,
            'llm_available': True  # This would be dynamically checked in a real implementation
        }
    
    @app.get("/api/ping")
    def ping():
        """Simple ping endpoint for connectivity testing from the client."""
        return {
            'status': 'pong',
            'message': 'Server is reachable'
        }
    
    return app

# Create the app instance
app = create_app()

if __name__ == '__main__':
    import uvicorn
    
    # Get configuration from centralized config
    debug = config.DEBUG
    port = config.PORT
    
    logger.info(f"Starting server on port {port} with debug={debug}")
    
    # Run with Uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=debug)
