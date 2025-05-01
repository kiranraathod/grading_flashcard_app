"""
Service for analyzing job descriptions and generating interview questions.
"""
import logging
import json
from typing import Dict, Any, List

from src.services.llm_service import LLMService

# Configure logging
logger = logging.getLogger(__name__)

class JobDescriptionService:
    """Service for analyzing job descriptions and generating interview questions."""
    
    def __init__(self, llm_service: LLMService):
        """Initialize the service."""
        self.llm_service = llm_service
        logger.debug("Initializing JobDescriptionService")
    
    async def analyze_job_description(self, job_description_text: str) -> Dict[str, Any]:
        """
        Analyze a job description to extract key information.
        
        Args:
            job_description_text: The full text of the job description
            
        Returns:
            Dictionary containing extracted skills, requirements and categories
        """
        logger.info("Analyzing job description")
        
        # Create prompt for the LLM
        prompt = self._create_analysis_prompt(job_description_text)
        
        try:
            # Use the LLM service's generate_content method with asyncio
            import asyncio
            
            # Setup the model similar to LLM service
            model = self.llm_service.client.GenerativeModel(
                self.llm_service.model,
                generation_config={
                    "temperature": 0.2,  # Lower temperature for more focused analysis
                    "max_output_tokens": 2048
                }
            )
            
            # Use asyncio.to_thread to run the synchronous method without blocking
            response_text = await asyncio.wait_for(
                asyncio.to_thread(lambda: model.generate_content(prompt).text),
                timeout=self.llm_service.timeout
            )
            
            # Parse the response - strip code blocks if present
            try:
                # Strip code blocks if present with a more robust regex approach
                if "```json" in response_text:
                    import re
                    match = re.search(r'```json\s*([\s\S]*?)\s*```', response_text)
                    if match:
                        response_text = match.group(1).strip()
                elif "```" in response_text:
                    import re
                    match = re.search(r'```\s*([\s\S]*?)\s*```', response_text)
                    if match:
                        response_text = match.group(1).strip()
                
                # Clean control characters from the JSON response
                import re
                # Replace all control characters except \n and \r with spaces
                response_text = re.sub(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f]', ' ', response_text)
                # Normalize whitespace
                response_text = re.sub(r'\s+', ' ', response_text)
                # Fix any broken JSON structure (common issues with LLM responses)
                response_text = response_text.replace('\\n', '\\\\n').replace('\\r', '\\\\r')
                
                analysis_result = json.loads(response_text)
                logger.debug(f"Successfully parsed job analysis: {analysis_result}")
                return analysis_result
            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse job analysis response: {e}")
                logger.debug(f"Raw response: {response_text}")
                # Return a simplified result if parsing fails
                return {
                    "required_skills": [],
                    "desired_skills": [],
                    "experience_level": "mid",
                    "domain_knowledge": [],
                    "soft_skills": [],
                    "technologies": []
                }
        except Exception as e:
            logger.error(f"Error analyzing job description: {str(e)}")
            # Return empty results on error
            return {
                "required_skills": [],
                "desired_skills": [],
                "experience_level": "mid",
                "domain_knowledge": [],
                "soft_skills": [],
                "technologies": []
            }
    
    async def generate_questions(
        self, 
        job_analysis: Dict[str, Any],
        categories: List[str],
        difficulty_levels: List[str],
        count_per_category: int = 3,
        max_retries: int = 2
    ) -> List[Dict[str, Any]]:
        """
        Generate interview questions based on job analysis.
        
        Args:
            job_analysis: The analysis result from analyze_job_description
            categories: Question categories to include (technical, applied, behavioral, case)
            difficulty_levels: Difficulty levels to include (entry, mid, senior)
            count_per_category: Number of questions per category
            max_retries: Maximum number of retry attempts per category
            
        Returns:
            List of generated questions with metadata
        """
        logger.info(f"Generating questions for categories: {categories}")
        
        all_questions = []
        
        for category in categories:
            success = False
            retry_count = 0
            
            while not success and retry_count <= max_retries:
                if retry_count > 0:
                    logger.info(f"Retry attempt {retry_count} for category {category}")
                
                # Create category-specific prompt
                prompt = self._create_question_generation_prompt(
                    job_analysis, 
                    category,
                    difficulty_levels,
                    count_per_category
                )
                
                try:
                    # Setup the model similar to LLM service
                    import asyncio
                    
                    model = self.llm_service.client.GenerativeModel(
                        self.llm_service.model,
                        generation_config={
                            "temperature": 0.7,  # Higher temperature for creative questions
                            "max_output_tokens": 4096
                        }
                    )
                    
                    # Use asyncio.to_thread to run the synchronous method without blocking
                    response_text = await asyncio.wait_for(
                        asyncio.to_thread(lambda: model.generate_content(prompt).text),
                        timeout=self.llm_service.timeout
                    )
                    
                    # Parse the questions
                    try:
                        # Use more robust regex approach for extracting JSON from markdown code blocks
                        if "```json" in response_text:
                            import re
                            match = re.search(r'```json\s*([\s\S]*?)\s*```', response_text)
                            if match:
                                response_text = match.group(1).strip()
                        elif "```" in response_text:
                            import re
                            match = re.search(r'```\s*([\s\S]*?)\s*```', response_text)
                            if match:
                                response_text = match.group(1).strip()
                        
                        # Clean control characters from the JSON response
                        import re
                        # Replace all control characters except \n and \r with spaces
                        response_text = re.sub(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f]', ' ', response_text)
                        # Normalize whitespace
                        response_text = re.sub(r'\s+', ' ', response_text)
                        # Fix any broken JSON structure (common issues with LLM responses)
                        response_text = response_text.replace('\\n', '\\\\n').replace('\\r', '\\\\r')
                                          
                        # Now parse the cleaned JSON
                        questions = json.loads(response_text)
                        logger.debug(f"Generated {len(questions)} questions for category {category}")
                        all_questions.extend(questions)
                        success = True  # Set success flag to exit retry loop
                    except json.JSONDecodeError as e:
                        retry_count += 1
                        logger.error(f"Failed to parse questions for category {category}: {e} (Attempt {retry_count}/{max_retries+1})")
                        logger.debug(f"Raw response: {response_text}")
                        if retry_count > max_retries:
                            # Return error instead of fallback questions
                            logger.warning(f"All {max_retries+1} attempts failed for category {category}.")
                            raise json.JSONDecodeError(f"Failed to parse questions for category {category} after {max_retries+1} attempts", "", 0)
                except Exception as e:
                    retry_count += 1
                    logger.error(f"Error generating questions for category {category}: {str(e)} (Attempt {retry_count}/{max_retries+1})")
                    if retry_count > max_retries:
                        # Return error instead of fallback questions
                        logger.warning(f"All {max_retries+1} attempts failed for category {category}.")
                        raise Exception(f"Failed to generate questions for category {category} after {max_retries+1} attempts")
        
        return all_questions
    
    def _create_analysis_prompt(self, job_description: str) -> str:
        """Create a prompt for analyzing a job description."""
        return f"""
        You are an expert job analyst with deep experience in technical hiring.
        
        Analyze this job description and extract the following information in JSON format:
        
        JOB DESCRIPTION:
        {job_description}
        
        Extract and return ONLY a JSON object with the following structure:
        {{
            "required_skills": ["skill1", "skill2", ...],
            "desired_skills": ["skill1", "skill2", ...],
            "experience_level": "entry|mid|senior",
            "domain_knowledge": ["domain1", "domain2", ...],
            "soft_skills": ["skill1", "skill2", ...],
            "technologies": ["tech1", "tech2", ...]
        }}
        
        Be specific and granular with the skills and technologies. Extract actual names of programming languages, frameworks, methodologies, etc.
        
        IMPORTANT: Return only valid JSON that can be parsed by standard JSON parsers. Do not include any control characters, tab characters, or any non-ASCII characters in your response. Do not include any markdown code blocks or additional explanation - ONLY return the raw JSON object.
        """
    
    def _create_question_generation_prompt(
        self, 
        job_analysis: Dict[str, Any],
        category: str,
        difficulty_levels: List[str],
        count: int
    ) -> str:
        """Create a prompt for generating interview questions."""
        # Extract relevant skills based on category
        relevant_skills = []
        if category == "technical":
            relevant_skills = job_analysis.get("required_skills", []) + job_analysis.get("technologies", [])
        elif category == "applied":
            relevant_skills = job_analysis.get("required_skills", []) + job_analysis.get("domain_knowledge", [])
        elif category == "behavioral":
            relevant_skills = job_analysis.get("soft_skills", [])
        elif category == "case":
            relevant_skills = job_analysis.get("domain_knowledge", [])
        elif category == "job":
            # For job-specific questions, use all skills and knowledge
            relevant_skills = job_analysis.get("required_skills", []) + \
                             job_analysis.get("desired_skills", []) + \
                             job_analysis.get("domain_knowledge", []) + \
                             job_analysis.get("technologies", [])
            
        # Format the difficulty levels for the prompt
        difficulty_str = ", ".join(difficulty_levels)
        
        # Create the prompt - request ONE high-quality question with specific difficulty
        return f"""
        You are an expert technical interviewer with deep knowledge in hiring for technical roles.
        
        Generate ONE high-quality interview question in the "{category}" category with a difficulty level of {difficulty_levels[0]}.
        
        The question should be relevant to these skills and technologies:
        {", ".join(relevant_skills) if relevant_skills else "general skills for the job role"}
        
        For the question:
        1. Make it specific and challenging, appropriate for {difficulty_levels[0]} difficulty
        2. Ensure it evaluates real-world knowledge and not just theoretical concepts
        3. Create a question that can't be answered with a simple Google search
        4. Include a BRIEF example answer (maximum 3-4 paragraphs) that demonstrates mastery
        
        Return your response as a JSON array with this structure:
        [
            {{
                "text": "question text",
                "category": "{category}",
                "subtopic": "specific skill or technology",
                "difficulty": "{difficulty_levels[0]}",
                "answer": "concise example answer (3-4 paragraphs maximum)"
            }}
        ]
        
        EXTREMELY IMPORTANT: 
        1. Return ONLY valid JSON that can be parsed by standard JSON parsers
        2. DO NOT include any control characters, tab characters, or any non-ASCII characters
        3. DO NOT use any markdown formatting, code blocks, or extra explanations
        4. For any multi-line text (like the answer), use a single space to replace newlines
        5. Escape all quotes properly in your response
        6. Return the bare JSON array with no additional markdown or formatting
        """
    
    # Remove fallback question generation method - no longer needed