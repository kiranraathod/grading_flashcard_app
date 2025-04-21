"""
Controller for interview question grading operations.
"""
from fastapi import HTTPException
import logging
import json
from typing import Dict, Any, List, Optional

# Configure logging
logger = logging.getLogger(__name__)

class InterviewGradingController:
    """Controller for handling interview answer grading operations."""
    
    def __init__(self):
        """Initialize the controller."""
        logger.debug("Initializing InterviewGradingController")
        # You would initialize your LLM client here
    
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
            
            # Send the prompt to the LLM
            # In a real implementation, you would call your LLM here
            # For now, we'll simulate a response with a mock LLM call
            llm_response = await self._mock_llm_call(prompt)
            
            # Parse the LLM response to extract grade, feedback, and suggestions
            result = self._parse_llm_response(llm_response)
            
            logger.info(f"Grading complete. Score: {result['score']}/100")
            return result
            
        except Exception as e:
            logger.error(f"Error grading interview answer: {str(e)}")
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
        
        Format your response as a JSON object with the following structure:
        {{
            "score": <numerical_score>,
            "feedback": "<detailed_feedback>",
            "suggestions": ["<suggestion_1>", "<suggestion_2>", ...]
        }}
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
    
    async def _mock_llm_call(self, prompt: str) -> str:
        """
        Mock LLM response for testing purposes.
        
        In a real implementation, this would call an actual LLM API.
        """
        logger.debug("Calling mock LLM (would call real LLM in production)")
        
        # Simulate different responses based on prompt content
        if "technical" in prompt.lower():
            return json.dumps({
                "score": 78,
                "feedback": "The answer demonstrates good technical knowledge but could be more detailed in explaining the implementation process. The concepts are accurately described, but some practical considerations are missing.",
                "suggestions": [
                    "Include more specific examples of implementation challenges",
                    "Explain the trade-offs between different approaches",
                    "Mention performance considerations",
                    "Discuss how you would test your solution"
                ]
            })
        elif "behavioral" in prompt.lower():
            return json.dumps({
                "score": 85,
                "feedback": "Good use of the STAR method with a clear situation and actions taken. The results could be quantified more specifically, and there could be more reflection on what was learned.",
                "suggestions": [
                    "Quantify your results with specific metrics",
                    "Include what you learned from the experience",
                    "Highlight more of your specific contributions",
                    "Connect your actions more directly to the outcomes"
                ]
            })
        else:
            return json.dumps({
                "score": 72,
                "feedback": "The answer addresses the main points of the question but lacks depth in some areas. The structure is logical, but some arguments could be supported with more evidence.",
                "suggestions": [
                    "Provide more specific examples to support your points",
                    "Consider addressing potential counterarguments",
                    "Expand on the practical implications of your approach",
                    "Clarify how you would measure the success of your solution"
                ]
            })
    
    def _parse_llm_response(self, llm_response: str) -> Dict[str, Any]:
        """
        Parse the LLM response into a structured format.
        
        Args:
            llm_response: The raw response from the LLM
            
        Returns:
            Structured dictionary with score, feedback, and suggestions
        """
        try:
            # Parse the JSON response
            parsed = json.loads(llm_response)
            
            # Validate the response format
            required_fields = ["score", "feedback", "suggestions"]
            for field in required_fields:
                if field not in parsed:
                    raise ValueError(f"Missing required field '{field}' in LLM response")
            
            # Ensure score is within range
            score = parsed["score"]
            if not isinstance(score, (int, float)) or score < 0 or score > 100:
                raise ValueError(f"Score must be a number between 0 and 100, got: {score}")
            
            # Ensure suggestions is a list
            if not isinstance(parsed["suggestions"], list):
                raise ValueError("Suggestions must be a list")
            
            # Format the result
            result = {
                "score": score,
                "feedback": parsed["feedback"],
                "suggestions": parsed["suggestions"]
            }
            
            return result
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse LLM response as JSON: {str(e)}")
            logger.debug(f"Raw response: {llm_response}")
            
            # Return a fallback response
            return {
                "score": 50,
                "feedback": "We couldn't properly analyze your answer. Please try again later.",
                "suggestions": [
                    "Review the key concepts related to this topic",
                    "Try to be more specific in your answer",
                    "Structure your response more clearly"
                ]
            }
