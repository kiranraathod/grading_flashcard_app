class AnswerModel:
    """
    Data model for user answers and grading results
    """
    
    def __init__(self, flashcard_id, question, user_answer, grade=None, feedback=None, suggestions=None):
        self.flashcard_id = flashcard_id
        self.question = question
        self.user_answer = user_answer
        self.grade = grade
        self.feedback = feedback
        self.suggestions = suggestions or []
        
    def to_dict(self):
        return {
            'flashcardId': self.flashcard_id,
            'question': self.question,
            'userAnswer': self.user_answer,
            'grade': self.grade,
            'feedback': self.feedback,
            'suggestions': self.suggestions
        }
    
    @classmethod
    def from_dict(cls, data):
        return cls(
            flashcard_id=data.get('flashcardId'),
            question=data.get('question'),
            user_answer=data.get('userAnswer'),
            grade=data.get('grade'),
            feedback=data.get('feedback'),
            suggestions=data.get('suggestions', [])
        )