from pydantic import BaseModel, Field
from typing import List, Optional

# Request models
class GradeRequest(BaseModel):
    flashcardId: str
    question: str
    userAnswer: str

class SuggestionRequest(BaseModel):
    flashcardId: str

class FeedbackRequest(BaseModel):
    flashcardId: str
    userFeedback: str

# Response models
class GradeResponse(BaseModel):
    grade: str
    feedback: str
    suggestions: List[str] = Field(default_factory=list)
    error: Optional[str] = None

class SuggestionResponse(BaseModel):
    flashcardId: str
    suggestions: List[str]

class FeedbackResponse(BaseModel):
    status: str = "success"
