from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any


class GradeRequest(BaseModel):
    flashcardId: str = Field(..., description="The unique identifier of the flashcard")
    question: str = Field(..., description="The flashcard question")
    userAnswer: str = Field(..., description="The user's answer to the question")
    userId: Optional[str] = Field(None, description="Optional user identifier")


class GradeResponse(BaseModel):
    grade: str = Field(..., description="Letter grade assigned to the answer (A-F)")
    feedback: str = Field(..., description="Detailed feedback on the answer")
    suggestions: List[str] = Field(..., description="Suggestions for improvement")
    error: Optional[str] = Field(None, description="Error message if something went wrong")


class SuggestionRequest(BaseModel):
    flashcardId: str = Field(..., description="The unique identifier of the flashcard")


class SuggestionResponse(BaseModel):
    flashcardId: str = Field(..., description="The unique identifier of the flashcard")
    suggestions: List[str] = Field(..., description="Suggestions for improvement")


class FeedbackRequest(BaseModel):
    flashcardId: str = Field(..., description="The unique identifier of the flashcard")
    userFeedback: str = Field(..., description="User's feedback on the grading")


class CardProgressRequest(BaseModel):
    cardId: str = Field(..., description="The unique identifier of the flashcard")
    confidenceLevel: int = Field(..., ge=0, le=5, description="User's confidence level (0-5)")


class LearningStats(BaseModel):
    cardsLearned: int = Field(..., description="Number of cards learned")
    averageConfidence: float = Field(..., description="Average confidence level")
    streakDays: int = Field(..., description="Number of consecutive days with activity")
    error: Optional[str] = Field(None, description="Error message if something went wrong")


class DueCardsResponse(BaseModel):
    dueCards: List[Dict[str, Any]] = Field(..., description="List of cards due for review")
    count: int = Field(..., description="Number of due cards")
