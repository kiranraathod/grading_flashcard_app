from pydantic import BaseModel, Field, validator
from typing import List, Optional
import re

class GradeRequest(BaseModel):
    flashcardId: str
    question: str
    userAnswer: str
    correctAnswer: str  # Add this new field
    
    @validator('flashcardId')
    def validate_flashcard_id(cls, v):
        if not v or not v.strip():
            raise ValueError("flashcardId cannot be empty")
        if len(v) > 50:
            raise ValueError("flashcardId is too long (max 50 characters)")
        return v
        
    @validator('question')
    def validate_question(cls, v):
        if not v or not v.strip():
            raise ValueError("question cannot be empty")
        if len(v) > 1000:
            raise ValueError("question is too long (max 1000 characters)")
        return v.strip()
        
    @validator('userAnswer')
    def validate_user_answer(cls, v):
        if v is None:
            raise ValueError("userAnswer cannot be null")
        # Allow empty answers for cases where the user didn't know the answer
        return v.strip() if v else ""
        
    @validator('correctAnswer')
    def validate_correct_answer(cls, v):
        if not v or not v.strip():
            raise ValueError("correctAnswer cannot be empty")
        if len(v) > 1000:
            raise ValueError("correctAnswer is too long (max 1000 characters)")
        return v.strip()

class SuggestionRequest(BaseModel):
    flashcardId: str
    
    @validator('flashcardId')
    def validate_flashcard_id(cls, v):
        if not v or not v.strip():
            raise ValueError("flashcardId cannot be empty")
        return v

class FeedbackRequest(BaseModel):
    flashcardId: str
    userFeedback: str
    
    @validator('flashcardId')
    def validate_flashcard_id(cls, v):
        if not v or not v.strip():
            raise ValueError("flashcardId cannot be empty")
        return v
        
    @validator('userFeedback')
    def validate_user_feedback(cls, v):
        if not v or not v.strip():
            raise ValueError("userFeedback cannot be empty")
        if len(v) > 2000:
            raise ValueError("userFeedback is too long (max 2000 characters)")
        return v.strip()

# Response models with validation
class GradeResponse(BaseModel):
    grade: str
    feedback: str
    suggestions: List[str] = Field(default_factory=list)
    error: Optional[str] = None
    
    @validator('grade')
    def validate_grade(cls, v):
        valid_grades = ['A', 'B', 'C', 'D', 'F', 'X']  # X for system errors
        if v not in valid_grades:
            raise ValueError(f"Invalid grade: {v}. Must be one of {valid_grades}")
        return v
    
    @validator('suggestions')
    def validate_suggestions(cls, v):
        if not v:
            # Provide default suggestions if empty
            return ["Review the material", "Practice with more examples"]
        if len(v) > 10:
            # Limit number of suggestions
            return v[:10]
        return v

class SuggestionResponse(BaseModel):
    flashcardId: str
    suggestions: List[str]
    
    @validator('suggestions')
    def validate_suggestions(cls, v):
        if not v:
            return ["Review the material", "Practice with more examples"]
        if len(v) > 10:
            return v[:10]
        return v

class FeedbackResponse(BaseModel):
    status: str = "success"
    message: Optional[str] = None
