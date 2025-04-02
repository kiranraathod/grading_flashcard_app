from flask import Flask, request, jsonify
from flask_cors import CORS
import os

app = Flask(__name__)

# Enable CORS for all routes
CORS(app, 
    resources={r"/*": {
        "origins": [
            "http://localhost:50202",
            "http://127.0.0.1:50202",
            "http://localhost:3000",
            "http://127.0.0.1:3000"
        ],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }},
    supports_credentials=True
)

@app.route('/')
def index():
    return jsonify({
        "status": "online",
        "message": "Simple test server is running"
    })

@app.route('/api/test', methods=['GET'])
def test():
    return jsonify({
        "message": "GET test successful"
    })

@app.route('/api/grade', methods=['POST'])
def grade():
    data = request.json
    print(f"Received grade request: {data}")
    
    # Simple hardcoded response for testing
    return jsonify({
        "grade": "A",
        "feedback": "Your answer is correct. Paris is the capital of France.",
        "suggestions": [
            "Consider capitalizing proper nouns like 'Paris'",
            "You could add that Paris is also the largest city in France"
        ]
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3000))
    print(f"Starting simple test server on port {port}")
    app.run(host='0.0.0.0', port=port, debug=True)
