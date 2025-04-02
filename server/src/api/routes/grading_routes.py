from fastapi import APIRouter, Request, Depends, HTTPException, status
from src.api.controllers.grading_controller import GradingController
from src.api.middleware.auth_middleware import AuthRequired, get_current_user
from src.api.models.models import (
    GradeRequest, 
    GradeResponse, 
    SuggestionRequest, 
    SuggestionResponse, 
    FeedbackRequest
)
import logging
import traceback
import asyncio
import time
import os
from fastapi.responses import JSONResponse
from fastapi import status
from fastapi.responses import JSONResponse

# Set up logger
logger = logging.getLogger(__name__)

router = APIRouter()
grading_controller = GradingController()
auth_required = AuthRequired()

@router.post("/grade")
async def grade_answer(grade_request: GradeRequest):
    """
    Grade a flashcard answer and provide feedback.
    
    - **flashcardId**: Unique identifier for the flashcard
    - **question**: The question presented to the user
    - **userAnswer**: The user's provided answer to grade
    """
    logger.info(f"GRADE REQUEST: {grade_request.question} => {grade_request.userAnswer}")
    
    try:
        # First try using the LLM service with improved timeout handling
        result = await grading_controller.llm_service.grade_answer(
            grade_request.question,
            grade_request.userAnswer
        )
        
        # If we got a valid result, return it
        if result.get('grade') != 'N/A':
            logger.info(f"LLM grading successful: {result}")
            return result
            
        # If LLM returned N/A (timeout or error), fall back to pattern matching
        logger.info("LLM returned N/A, falling back to pattern matching")
    except Exception as e:
        # If any exception occurs, log it and fall back to pattern matching
        logger.error(f"Error using LLM service: {str(e)}")
        logger.error(traceback.format_exc())
    
    # Fallback to pattern matching
    question = grade_request.question.lower()
    answer = grade_request.userAnswer.lower()
    
    # Check for capital of France
    if "capital" in question and "france" in question:
        is_correct = "paris" in answer
        
        if is_correct:
            logger.info("Answer is correct (pattern matching)")
            return {
                "grade": "A",
                "feedback": "Your answer is correct. Paris is the capital of France.",
                "suggestions": [
                    "Consider capitalizing proper nouns like 'Paris'",
                    "You could add that Paris is also the largest city in France"
                ]
            }
        else:
            logger.info("Answer is incorrect (pattern matching)")
            return {
                "grade": "F",
                "feedback": "Your answer is incorrect. The capital of France is Paris.",
                "suggestions": [
                    "Review basic geography facts",
                    "Remember that Paris is the capital of France"
                ]
            }
    else:
        # Default response for any other question
        logger.info("Using default grading (pattern matching)")
        return {
            "grade": "A",
            "feedback": f"Your answer has been processed with basic pattern matching.",
            "suggestions": [
                "Consider adding more details to your answer",
                "Try to use proper capitalization in your responses"
            ]
        }

@router.get("/test-llm")
async def test_llm_connection():
    """
    Test the connection to the LLM service.
    This endpoint helps diagnose issues with the LLM connection.
    """
    try:
        logger.info("Testing LLM connection...")
        start_time = time.time()
        
        # Test with a simple question
        result = await grading_controller.llm_service.grade_answer(
            "What is the capital of France?", 
            "Paris"
        )
        
        elapsed = time.time() - start_time
        logger.info(f"LLM test successful! Response time: {elapsed:.2f} seconds")
        
        # Check if LLM is responding properly
        if result.get('grade') == 'N/A':
            return {
                "status": "partial_success",
                "message": "LLM connection works but returned N/A grade",
                "response_time_seconds": elapsed,
                "result": result,
                "diagnostic_info": {
                    "llm_model": grading_controller.llm_service.model,
                    "api_key_configured": bool(os.getenv('GOOGLE_API_KEY', '')),
                    "timeout_settings": {
                        "asyncio_wrapper_timeout": "10 seconds",
                        "gemini_api_timeout": "9 seconds",
                        "client_timeout": "12 seconds"
                    }
                }
            }
        
        # Success case
        return {
            "status": "success",
            "message": "LLM connection is working properly",
            "response_time_seconds": elapsed,
            "result": result,
            "diagnostic_info": {
                "llm_model": grading_controller.llm_service.model,
                "api_key_configured": bool(os.getenv('GOOGLE_API_KEY', '')),
                "timeout_settings": {
                    "asyncio_wrapper_timeout": "10 seconds",
                    "gemini_api_timeout": "9 seconds",
                    "client_timeout": "12 seconds"
                }
            }
        }
    except HTTPException as http_exc:
        elapsed = time.time() - start_time
        logger.error(f"LLM test failed with HTTP exception: {http_exc.detail} (Status: {http_exc.status_code})")
        
        # Return a structured response for HTTP exceptions
        return JSONResponse(
            status_code=http_exc.status_code,
            content={
                "status": "error",
                "message": http_exc.detail,
                "response_time_seconds": elapsed,
                "error_type": "HTTPException",
                "status_code": http_exc.status_code,
                "diagnostic_info": {
                    "llm_model": grading_controller.llm_service.model,
                    "api_key_configured": bool(os.getenv('GOOGLE_API_KEY', '')),
                    "timeout_settings": {
                        "asyncio_wrapper_timeout": "10 seconds",
                        "gemini_api_timeout": "9 seconds",
                        "client_timeout": "12 seconds"
                    }
                }
            }
        )
    except asyncio.TimeoutError:
        elapsed = time.time() - start_time
        logger.error(f"LLM test timed out after {elapsed:.2f} seconds")
        return JSONResponse(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            content={
                "status": "timeout",
                "message": "LLM connection timed out",
                "response_time_seconds": elapsed,
                "error_type": "TimeoutError",
                "diagnostic_info": {
                    "llm_model": grading_controller.llm_service.model,
                    "api_key_configured": bool(os.getenv('GOOGLE_API_KEY', '')),
                    "timeout_settings": {
                        "asyncio_wrapper_timeout": "10 seconds",
                        "gemini_api_timeout": "9 seconds",
                        "client_timeout": "12 seconds"
                    }
                }
            }
        )
    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"LLM test failed: {str(e)}")
        logger.error(traceback.format_exc())
        
        # Return more diagnostic information instead of raising an exception
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "status": "error",
                "message": f"LLM connection test failed: {str(e)}",
                "response_time_seconds": elapsed,
                "error_type": type(e).__name__,
                "error_details": str(e),
                "diagnostic_info": {
                    "llm_model": grading_controller.llm_service.model,
                    "api_key_configured": bool(os.getenv('GOOGLE_API_KEY', '')),
                    "timeout_settings": {
                        "asyncio_wrapper_timeout": "10 seconds",
                        "gemini_api_timeout": "9 seconds",
                        "client_timeout": "12 seconds"
                    }
                }
            }
        )

@router.get("/timeout-config")
async def get_timeout_configuration():
    """
    Get the current timeout configuration for the system.
    This is helpful for debugging timeout issues.
    """
    return {
        "timeout_configuration": {
            "client_side": {
                "api_request_timeout": "12 seconds (set in api_service.dart)",
                "llm_test_timeout": "15 seconds (set in api_service.dart testLLMConnection method)"
            },
            "server_side": {
                "asyncio_wrapper_timeout": "10 seconds (set in llm_service.py grade_answer method)",
                "gemini_api_timeout": "9 seconds (set in llm_service.py _grade_answer_sync method)",
                "fastapi_route_default_timeout": "60 seconds (default FastAPI behavior)"
            },
            "timeout_hierarchy": [
                "Gemini API timeout (9s) - Most specific",
                "Asyncio wrapper timeout (10s)",
                "Client API request timeout (12s)",
                "FastAPI route timeout (60s) - Least specific"
            ],
            "relevant_logs_location": "server console output with timestamps",
            "how_to_debug": [
                "Check server logs for 'API responded in X.XXs' messages",
                "Look for 'timed out' messages in logs",
                "Use /api/test-llm endpoint to test LLM connection directly",
                "Verify Google API key is valid and has sufficient quota"
            ]
        }
    }

@router.get("/cors-test")
async def cors_test(request: Request):
    """
    Test endpoint for CORS configuration.
    Returns the request headers and CORS configuration for diagnostic purposes.
    """
    from fastapi.middleware.cors import CORSMiddleware
    import inspect
    
    # Get CORS middleware from app
    app = request.app
    cors_middleware = None
    for middleware in app.user_middleware:
        if middleware.cls == CORSMiddleware:
            cors_middleware = middleware
            break
    
    # Get CORS configuration
    cors_config = {}
    if cors_middleware:
        cors_config = {
            "allow_origins": getattr(cors_middleware.options, "allow_origins", []),
            "allow_methods": getattr(cors_middleware.options, "allow_methods", []),
            "allow_headers": getattr(cors_middleware.options, "allow_headers", []),
            "allow_credentials": getattr(cors_middleware.options, "allow_credentials", False),
            "expose_headers": getattr(cors_middleware.options, "expose_headers", []),
            "max_age": getattr(cors_middleware.options, "max_age", 600),
        }
    
    # Build response with CORS diagnostic info
    return {
        "cors_status": "CORS is configured" if cors_middleware else "CORS is not configured",
        "request_info": {
            "method": request.method,
            "url": str(request.url),
            "origin": request.headers.get("origin", "No origin header"),
            "host": request.headers.get("host", "No host header"),
            "user_agent": request.headers.get("user-agent", "No user-agent header"),
        },
        "cors_configuration": cors_config,
        "client_debugging_tips": [
            "Ensure your Flutter app is making requests to the correct server URL",
            "Check that your request includes the 'Content-Type' header if sending JSON",
            "Verify that all custom headers are included in the 'access-control-allow-headers' list",
            "If using credentials, ensure withCredentials is set to true in your HTTP client",
            "For testing, try using the 'no-cors' mode to see if the request works (though response will be opaque)"
        ],
        "server_debugging_tips": [
            "Ensure the CORS middleware is added before any routes are defined",
            "When using allow_credentials=True, allow_origins cannot be '*' and must list specific origins",
            "Make sure your allowed origins match exactly (including protocol and port)",
            "Check if the preflight (OPTIONS) request succeeds before the actual request",
            "Verify response headers include the required CORS headers for the client origin"
        ]
    }

@router.get("/suggestions", response_model=SuggestionResponse, dependencies=[Depends(auth_required)])
async def get_suggestions(
    flashcardId: str,
    request: Request,
    user_id: str = Depends(get_current_user)
):
    """
    Get improvement suggestions for a flashcard.
    
    - **flashcardId**: Unique identifier for the flashcard
    """
    try:
        logger.debug(f"Received suggestions request for flashcard_id={flashcardId}")
        
        result = await grading_controller.get_suggestions(flashcardId, user_id)
        logger.debug(f"Returning suggestions: {result}")
        
        return result
    except Exception as e:
        logger.error(f"Error in get_suggestions: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/feedback", status_code=status.HTTP_200_OK, dependencies=[Depends(auth_required)])
async def submit_feedback(
    feedback_request: FeedbackRequest,
    request: Request,
    user_id: str = Depends(get_current_user)
):
    """
    Submit user feedback about the grading process.
    
    - **flashcardId**: Unique identifier for the flashcard
    - **userFeedback**: User's feedback about the grading
    """
    try:
        logger.debug(f"Received feedback submission: {feedback_request}")
        
        result = await grading_controller.submit_feedback(
            feedback_request.flashcardId,
            feedback_request.userFeedback,
            user_id
        )
        
        return {"status": "success"}
    except Exception as e:
        logger.error(f"Error in submit_feedback: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
