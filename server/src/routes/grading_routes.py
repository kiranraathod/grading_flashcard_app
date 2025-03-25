from flask import Blueprint, request, jsonify
from src.controllers.grading_controller import GradingController
import logging

# Set up logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

grading_bp = Blueprint('grading', __name__)  
grading_controller = GradingController()

@grading_bp.route('/grade', methods=['POST'])
async def grade_answer():
    try:
        data = request.json
        logger.info(f"Received grading request: {data}")
        
        if not all(key in data for key in ['flashcardId', 'question', 'userAnswer']):
            logger.error("Missing required fields in request")
            return jsonify({'error': 'Missing required fields'}), 400
        
        logger.info("Calling grading controller...")
        try:
            result = await grading_controller.grade_answer(
                data['flashcardId'], 
                data['question'], 
                data['userAnswer']
            )
            logger.info(f"Grading result: {result}")
            response = jsonify(result)
            return response
        except Exception as inner_e:
            import traceback
            logger.error(f"Error in grading controller: {str(inner_e)}")
            logger.error(traceback.format_exc())
            raise inner_e
            
    except Exception as e:
        import traceback
        logger.error(f"Error in grade_answer endpoint: {str(e)}")
        logger.error(traceback.format_exc())
        return jsonify({'error': str(e)}), 500

@grading_bp.route('/suggestions', methods=['GET'])
async def get_suggestions():
    try:
        flashcard_id = request.args.get('flashcardId')
        
        if not flashcard_id:
            return jsonify({'error': 'Missing flashcardId parameter'}), 400
        
        result = await grading_controller.get_suggestions(flashcard_id)
        
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error in get_suggestions: {str(e)}")
        return jsonify({'error': str(e)}), 500

@grading_bp.route('/feedback', methods=['POST'])
async def submit_feedback():
    try:
        data = request.json
        
        if not all(key in data for key in ['flashcardId', 'userFeedback']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        await grading_controller.submit_feedback(
            data['flashcardId'], 
            data['userFeedback']
        )
        
        return jsonify({'status': 'success'})
    except Exception as e:
        logger.error(f"Error in submit_feedback: {str(e)}")
        return jsonify({'error': str(e)}), 500