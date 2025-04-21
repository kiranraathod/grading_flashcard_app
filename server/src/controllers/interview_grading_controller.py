"""
Controller for interview question grading operations with LLM integration.
"""
from fastapi import HTTPException
import logging
import json
import traceback
from typing import Dict, Any, List, Optional

from src.services.llm_service import LLMService
from src.utils.exceptions import LLMConnectionError, LLMResponseParsingError

# Configure logging
logger = logging.getLogger(__name__)

class InterviewGradingController:
    """Controller for handling interview answer grading operations."""
    
    def __init__(self):
        """Initialize the controller with LLM service."""
        logger.debug("Initializing InterviewGradingController with LLM service")
        self.llm_service = LLMService()
    
    async def grade_interview_answer(
        self, 
        question_id: str, 
        question_text: str, 
        user_answer: str,
        question_category: str,
        question_difficulty: str
    ) -> Dict[str, Any]:
        """
        Grade a user's answer to an interview question using the LLM.
        
        Args:
            question_id: Unique identifier for the interview question
            question_text: The interview question text
            user_answer: The user's response to the question
            question_category: Category of question (technical, behavioral, etc.)
            question_difficulty: Difficulty level of the question
            
        Returns:
            Dictionary containing the grade (score), feedback, and suggestions
            
        Raises:
            HTTPException: If there's an error during grading
        """
        try:
            logger.info(f"Grading interview answer for question {question_id}")
            logger.debug(f"Question: {question_text}")
            logger.debug(f"Category: {question_category}, Difficulty: {question_difficulty}")
            
            # Create a custom prompt for the LLM based on the interview question type
            prompt = self._create_grading_prompt(
                question_text, 
                user_answer,
                question_category,
                question_difficulty
            )
            
            try:
                # Use the enhanced LLM service to evaluate the answer
                result = await self.llm_service.grade_interview_answer(prompt)
                
                logger.info(f"Grading complete. Score: {result['score']}/100")
                return result
            
            except (LLMConnectionError, LLMResponseParsingError) as llm_error:
                logger.error(f"LLM error during interview answer grading: {str(llm_error)}")
                return self._create_fallback_response(f"LLM service error: {str(llm_error)}")
                
        except Exception as e:
            logger.error(f"Unexpected error grading interview answer: {str(e)}")
            logger.error(traceback.format_exc())
            raise HTTPException(
                status_code=500,
                detail=f"An error occurred during interview answer grading: {str(e)}"
            )
    
    def _create_grading_prompt(
        self, 
        question: str, 
        answer: str,
        category: str,
        difficulty: str
    ) -> str:
        """
        Create a custom prompt for the LLM to grade an interview answer.
        
        The prompt is tailored to the specific question category and difficulty.
        """
        # Base prompt with instructions for the LLM
        base_prompt = f"""
        You are an expert interviewer and evaluator specialized in {category} interviews.
        
        Please evaluate the following answer to an interview question. 
        The question is categorized as "{category}" with a difficulty level of "{difficulty}".
        
        QUESTION:
        {question}
        
        CANDIDATE'S ANSWER:
        {answer}
        
        EVALUATION INSTRUCTIONS:
        1. Evaluate the answer based on completeness, accuracy, clarity, and depth.
        2. Provide a numerical score from 0 to 100.
        3. Give specific, constructive feedback on the answer.
        4. Provide 3-5 suggestions for improvement.
        5. DO NOT repeat or reveal what a perfect or ideal answer would be.
        
        Your response must strictly conform to this JSON format:
        {{
            "score": <numerical_score>,
            "feedback": "<detailed_feedback>",
            "suggestions": ["<suggestion_1>", "<suggestion_2>", ...]
        }}
        
        Where:
        - numerical_score must be an integer between 0 and 100
        - detailed_feedback must include specific evaluation and encouragement
        - There must be 3-5 specific suggestions in the suggestions array
        
        Do not include any explanations, markdown formatting or any text outside the JSON structure.
        Return only the valid JSON object, nothing else.
        """
        
        # Add category-specific evaluation criteria
        if category == "technical":
            base_prompt += """
            Additional evaluation criteria for technical questions:
            - Technical accuracy and depth of knowledge
            - Appropriate use of terminology
            - Understanding of practical applications
            - Problem-solving approach
            """
        elif category == "behavioral":
            base_prompt += """
            Additional evaluation criteria for behavioral questions:
            - Structure (STAR method: Situation, Task, Action, Result)
            - Relevance of the example provided
            - Demonstration of skills and qualities
            - Reflection and learning
            """
        elif category == "case":
            base_prompt += """
            Additional evaluation criteria for case study questions:
            - Problem breakdown and analysis
            - Methodology and approach
            - Consideration of alternatives
            - Business acumen and practical thinking
            """
            
        return base_prompt
    
    def _create_fallback_response(self, error_message: str) -> Dict[str, Any]:
        """
        Create a fallback response when LLM grading fails.
        
        Args:
            error_message: The error message to include in the feedback
            
        Returns:
            Fallback response with generic score, feedback, and suggestions
        """
        logger.warning(f"Creating fallback response due to: {error_message}")
        
        return {
            "score": 50,  # Neutral score
            "feedback": f"We couldn't properly analyze your answer. {error_message}",
            "suggestions": [
                "Review the key concepts related to this topic",
                "Try to be more specific in your answer",
                "Structure your response more clearly",
                "Please try again later when our service is fully operational"
            ]
        }
