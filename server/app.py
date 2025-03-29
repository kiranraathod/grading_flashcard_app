from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import os
import logging
import sys
import json
from dotenv import load_dotenv
from src.routes.grading_routes import grading_bp
from src.routes.spaced_repetition_routes import spaced_bp
from src.routes.auth_routes import auth_bp
from src.routes.flashcard_routes import flashcard_bp
from src.routes.profile_routes import profile_bp
from src.utils.db_helper import init_db_pool

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
logging.getLogger('src.services.postgres_service').setLevel(logging.DEBUG)
logging.getLogger('src.services.auth_service').setLevel(logging.DEBUG)
logging.getLogger('src.services.llm_service').setLevel(logging.DEBUG)
logging.getLogger('src.controllers.grading_controller').setLevel(logging.DEBUG)
logging.getLogger('src.routes.grading_routes').setLevel(logging.DEBUG)
logging.getLogger('src.routes.spaced_repetition_routes').setLevel(logging.DEBUG)
logging.getLogger('src.routes.auth_routes').setLevel(logging.DEBUG)
logging.getLogger('src.routes.flashcard_routes').setLevel(logging.DEBUG)
logging.getLogger('src.routes.profile_routes').setLevel(logging.DEBUG)
logging.getLogger('werkzeug').setLevel(logging.INFO)

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '.env.local'))

def create_app():
    app = Flask(__name__)
    
    # Initialize database connection pool
    init_db_pool()
    
    # Get allowed origins from environment or use default
    allowed_origins = os.getenv('ALLOWED_ORIGINS', 'http://localhost:3000').split(',')
    
    # Enable CORS for all routes - allow all origins for development
    # Be explicit about allowing localhost origins for both ports 3000 and the port the Flutter app runs on
    CORS(app, 
         resources={r"/*": {"origins": ["http://localhost:*", "http://127.0.0.1:*", "chrome-extension://*"]}}, 
         supports_credentials=False, 
         methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
         allow_headers=["Content-Type", "Authorization", "Accept", "Origin", "X-Requested-With"])

    # Add a logger for requests
    @app.before_request
    def log_request_info():
        logger.debug('Request Headers: %s', request.headers)
        logger.debug('Request Body: %s', request.get_data())
        
    @app.after_request
    def log_response_info(response):
        logger.debug('Response Status: %s', response.status)
        logger.debug('Response Headers: %s', response.headers)
        if response.content_type == 'application/json':
            try:
                logger.debug('Response Body: %s', json.loads(response.get_data()))
            except:
                logger.debug('Response Body: %s', response.get_data())
        return response
    
    # Register blueprints
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(grading_bp, url_prefix='/api')
    app.register_blueprint(spaced_bp, url_prefix='/api/spaced')
    app.register_blueprint(flashcard_bp, url_prefix='/api')
    app.register_blueprint(profile_bp, url_prefix='/api')
    
    @app.route('/')
    def health_check():
        return {'status': 'online', 'service': 'flashcard-llm-api'}
    
    return app

if __name__ == '__main__':
    app = create_app()
    debug = True  # Force debug mode on
    port = int(os.getenv('PORT', 5000))
    
    # Make sure to host on 0.0.0.0 to allow external access
    app.run(host='0.0.0.0', port=port, debug=debug)
