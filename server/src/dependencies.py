"""
Dependency injection for the application.
"""
from fastapi import Depends

from src.services.llm_service import LLMService
from src.services.job_description_service import JobDescriptionService

# Singleton instances
_llm_service = None
_job_description_service = None

def get_llm_service() -> LLMService:
    """Get or create LLM service instance."""
    global _llm_service
    if _llm_service is None:
        _llm_service = LLMService()
    return _llm_service

def get_job_description_service() -> JobDescriptionService:
    """Get or create job description service instance."""
    global _job_description_service
    if _job_description_service is None:
        _job_description_service = JobDescriptionService(get_llm_service())
    return _job_description_service