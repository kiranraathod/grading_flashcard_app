"""
API routes for job description analysis and question generation.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

from src.services.job_description_service import JobDescriptionService
from src.dependencies import get_job_description_service

router = APIRouter()

class JobDescriptionAnalysisRequest(BaseModel):
    job_description: str

class QuestionGenerationRequest(BaseModel):
    job_analysis: Dict[str, Any]
    categories: List[str]
    difficulty_levels: List[str]
    count_per_category: Optional[int] = 3

@router.post("/api/job-description/analyze")
async def analyze_job_description(
    request: JobDescriptionAnalysisRequest,
    job_description_service: JobDescriptionService = Depends(get_job_description_service)
):
    """Analyze a job description and extract key information."""
    result = await job_description_service.analyze_job_description(request.job_description)
    return result

@router.post("/api/job-description/generate-questions")
async def generate_job_questions(
    request: QuestionGenerationRequest,
    job_description_service: JobDescriptionService = Depends(get_job_description_service)
):
    """Generate interview questions based on job description analysis."""
    try:
        questions = await job_description_service.generate_questions(
            request.job_analysis,
            request.categories,
            request.difficulty_levels,
            request.count_per_category
        )
        return questions
    except Exception as e:
        # Return 400 error with message instead of fallback questions
        raise HTTPException(status_code=400, detail=f"Failed to generate questions: {str(e)}")