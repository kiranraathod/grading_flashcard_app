
import os
import logging
import sys
from app import create_app

# Set up detailed logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

# Set log levels for specific modules
logging.getLogger('src.services.llm_service').setLevel(logging.DEBUG)
logging.getLogger('src.controllers.grading_controller').setLevel(logging.DEBUG)
logging.getLogger('src.routes.grading_routes').setLevel(logging.DEBUG)

# Create and run the app in debug mode
app = create_app()
port = int(os.getenv('PORT', 3000))

if __name__ == '__main__':
    print(f"Starting debug server on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=True)
