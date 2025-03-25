from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import logging
from dotenv import load_dotenv
from src.routes.grading_routes import grading_bp

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

def create_app():
    app = Flask(__name__)
    
    # Get allowed origins from environment or use default
    allowed_origins = os.getenv('ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
    
    # Enable CORS for all routes - allow all origins for development
    CORS(app, 
         resources={r"/*": {"origins": "*"}}, 
         supports_credentials=False, 
         methods=["GET", "POST", "OPTIONS"],
         allow_headers=["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"])

    # Add a logger for requests
    @app.after_request
    def log_request(response):
        logger.debug(f"Request: {request.method} {request.path} -> Status: {response.status_code}")
        return response
    
    # Register blueprints
    app.register_blueprint(grading_bp, url_prefix='/api')
    
    @app.route('/')
    def health_check():
        return {'status': 'online', 'service': 'flashcard-llm-api'}
    
    # Remove individual OPTIONS route since CORS middleware handles it
    
    return app

if __name__ == '__main__':
    app = create_app()
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    port = int(os.getenv('PORT', 5000))
    
    # Make sure to host on 0.0.0.0 to allow external access
    app.run(host='0.0.0.0', port=port, debug=debug)