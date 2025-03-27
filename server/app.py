from flask import Flask, request, jsonify, Response
from flask_cors import CORS
import os
import logging
import sys
import json
from dotenv import load_dotenv
from src.routes.grading_routes import grading_bp
from src.routes.spaced_repetition_routes import spaced_bp

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
logging.getLogger('src.controllers.grading_controller').setLevel(logging.DEBUG)
logging.getLogger('src.routes.grading_routes').setLevel(logging.DEBUG)
logging.getLogger('src.routes.spaced_repetition_routes').setLevel(logging.DEBUG)
logging.getLogger('werkzeug').setLevel(logging.INFO)

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
    app.register_blueprint(grading_bp, url_prefix='/api')
    app.register_blueprint(spaced_bp, url_prefix='/api/spaced')
    
    @app.route('/')
    def health_check():
        return {'status': 'online', 'service': 'flashcard-llm-api'}
    
    return app

if __name__ == '__main__':
    app = create_app()
    debug = True  # Force debug mode on
    port = int(os.getenv('PORT', 3000))
    
    # Make sure to host on 0.0.0.0 to allow external access
    app.run(host='0.0.0.0', port=port, debug=debug)
