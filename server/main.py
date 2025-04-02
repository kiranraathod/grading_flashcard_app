from fastapi import FastAPI, Request, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
import logging
import sys
import json
import time
from dotenv import load_dotenv
from src.api.routes.grading_routes import router as grading_router
from src.api.routes.spaced_repetition_routes import router as spaced_router
from src.api.middleware.auth_middleware import verify_token, get_current_user

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
logging.getLogger('src.services.supabase_service').setLevel(logging.DEBUG)
logging.getLogger('src.api.controllers.grading_controller').setLevel(logging.DEBUG)
logging.getLogger('src.api.routes.grading_routes').setLevel(logging.DEBUG)
logging.getLogger('src.api.routes.spaced_repetition_routes').setLevel(logging.DEBUG)

# Load environment variables
load_dotenv()

# =====================================
# Restore original LLM grading functionality
# =====================================
import shutil
original_controller_backup = os.path.join(os.path.dirname(__file__), 'src', 'api', 'controllers', 'grading_controller.py.backup')
original_controller_path = os.path.join(os.path.dirname(__file__), 'src', 'api', 'controllers', 'grading_controller.py')

try:
    # Restore the original controller from backup if it exists
    if os.path.exists(original_controller_backup):
        shutil.copy2(original_controller_backup, original_controller_path)
        logger.info("✅ Restored original grading controller with LLM functionality")
    else:
        logger.info("✅ Using existing grading controller")
except Exception as e:
    logger.error(f"Error restoring controller: {str(e)}")

def create_app():
    app = FastAPI(
        title="Flashcard Grading API",
        description="API for grading flashcard answers and managing spaced repetition",
        version="1.0.0"
    )
    
    # Get allowed origins from environment or use default
    allowed_origins = os.getenv('ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
    
    # Enable CORS with properly specified origins
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:50202",  # Flutter web app origin
            "http://localhost:3000",   # API server origin
            "http://127.0.0.1:50202",  # Alternative local address
            "http://127.0.0.1:3000",   # Alternative local address
        ],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["Content-Type", "Authorization", "Accept"],
        expose_headers=["Content-Type", "Content-Length"],
    )

    # Middleware for request/response logging
    @app.middleware("http")
    async def log_requests(request: Request, call_next):
        # Log request details
        logger.debug(f"Request path: {request.url.path}")
        logger.debug(f"Request headers: {request.headers}")
        
        # Get request body without consuming it
        body = await request.body()
        if body:
            try:
                logger.debug(f"Request body: {json.loads(body)}")
            except:
                logger.debug(f"Request body: {body}")
        
        # Add timing for performance monitoring
        start_time = time.time()
        response = await call_next(request)
        process_time = time.time() - start_time
        
        # Log response details
        logger.debug(f"Response status: {response.status_code}")
        logger.debug(f"Response headers: {response.headers}")
        logger.debug(f"Response time: {process_time:.4f}s")
        
        # Include timing header in response
        response.headers["X-Process-Time"] = str(process_time)
        return response

    # Include routers with explicit logging
    logger.info(f"🚨 Registering grading routes at /api prefix")
    app.include_router(grading_router, prefix="/api", tags=["grading"])
    
    logger.info(f"🚨 Registering spaced repetition routes at /api/spaced prefix")
    app.include_router(spaced_router, prefix="/api/spaced", tags=["spaced-repetition"])
    
    # Add a test route directly in main.py to verify routing is working
    @app.get("/api/test")
    async def test_route():
        logger.info("Test route called!")
        return {"status": "ok", "message": "Test route is working"}
    
    @app.get("/")
    async def health_check():
        return {"status": "online", "service": "flashcard-llm-api"}

    return app

app = create_app()

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 3000))
    debug = os.getenv("DEBUG", "True").lower() == "true"
    
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=debug)
