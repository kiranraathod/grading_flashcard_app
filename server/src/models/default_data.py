"""
Pydantic models for default data API responses.
"""
from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from datetime import datetime

class DefaultFlashcardResponse(BaseModel):
    """Response model for individual flashcard."""
    id: str = Field(..., description="Unique identifier for the flashcard")
    question: str = Field(..., description="The flashcard question")
    answer: str = Field(..., description="The correct answer")
    is_completed: bool = Field(default=False, description="Whether the flashcard has been completed")
    user_id: Optional[str] = Field(None, description="User ID for future Supabase compatibility")
    category_id: Optional[str] = Field(None, description="Category ID for future Supabase compatibility")

class DefaultFlashcardSetResponse(BaseModel):
    """Response model for flashcard set with embedded flashcards."""
    id: str = Field(..., description="Unique identifier for the flashcard set")
    title: str = Field(..., description="Title of the flashcard set")
    description: str = Field(..., description="Description of the flashcard set")
    is_draft: bool = Field(default=False, description="Whether this is a draft set")
    rating: float = Field(default=0.0, description="Average rating of the set")
    rating_count: int = Field(default=0, description="Number of ratings")
    flashcards: List[DefaultFlashcardResponse] = Field(..., description="List of flashcards in the set")
    user_id: Optional[str] = Field(None, description="User ID for future Supabase compatibility")
    category_id: Optional[str] = Field(None, description="Category ID for future Supabase compatibility")
    created_at: Optional[datetime] = Field(default_factory=datetime.now, description="Creation timestamp")
    last_updated: Optional[datetime] = Field(default_factory=datetime.now, description="Last update timestamp")

class DefaultInterviewQuestionResponse(BaseModel):
    """Response model for interview question."""
    id: str = Field(..., description="Unique identifier for the question")
    text: str = Field(..., description="The interview question text")
    category: str = Field(..., description="Question category (technical, applied, case, behavioral, job)")
    subtopic: str = Field(..., description="Specific subtopic within the category")
    difficulty: str = Field(..., description="Difficulty level (entry, mid, senior)")
    answer: Optional[str] = Field(None, description="Sample answer content")
    is_starred: bool = Field(default=False, description="Whether the question is starred")
    is_completed: bool = Field(default=False, description="Whether the question has been completed")
    is_draft: bool = Field(default=False, description="Whether this is a draft question")
    user_id: Optional[str] = Field(None, description="User ID for future Supabase compatibility")
    category_id: Optional[str] = Field(None, description="Category ID for future Supabase compatibility")

class DefaultSubtopicResponse(BaseModel):
    """Response model for category subtopic."""
    id: str = Field(..., description="Unique identifier for the subtopic")
    name: str = Field(..., description="Display name of the subtopic")
    category_id: str = Field(..., description="Parent category ID")

class DefaultCategoryResponse(BaseModel):
    """Response model for category with subtopics."""
    id: str = Field(..., description="Unique identifier for the category")
    name: str = Field(..., description="Display name of the category")
    color: str = Field(..., description="Hex color code for the category")
    icon: str = Field(..., description="Icon name for the category")
    subtopics: List[str] = Field(..., description="List of subtopic names")

class CategoryCountsResponse(BaseModel):
    """Response model for category question counts."""
    counts: Dict[str, int] = Field(..., description="Map of category names to question counts")
    total_questions: int = Field(..., description="Total number of questions across all categories")
    user_id: Optional[str] = Field(None, description="User ID for future Supabase compatibility")
    last_updated: datetime = Field(default_factory=datetime.now, description="When counts were last calculated")

class DefaultDataResponse(BaseModel):
    """Comprehensive response model for all default data."""
    flashcard_sets: List[DefaultFlashcardSetResponse] = Field(..., description="Default flashcard sets")
    interview_questions: List[DefaultInterviewQuestionResponse] = Field(..., description="Default interview questions")
    categories: List[DefaultCategoryResponse] = Field(..., description="Available categories")
    category_counts: CategoryCountsResponse = Field(..., description="Dynamic category counts")
    user_id: Optional[str] = Field(None, description="User ID for future Supabase compatibility")
    version: str = Field(..., description="API version")
    timestamp: datetime = Field(default_factory=datetime.now, description="Response generation timestamp")

class HealthCheckResponse(BaseModel):
    """Response model for health check endpoint."""
    status: str = Field(..., description="Service status")
    service: str = Field(..., description="Service name")
    categories_available: int = Field(..., description="Number of categories available")
    version: str = Field(..., description="Service version")
