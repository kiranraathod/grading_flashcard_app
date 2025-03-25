class FlashcardModel:
    """
    Data model for flashcards
    
    Note: In a production environment, this would likely be connected to a database
    """
    
    def __init__(self, id, question, answer):
        self.id = id
        self.question = question
        self.answer = answer
        
    def to_dict(self):
        return {
            'id': self.id,
            'question': self.question,
            'answer': self.answer
        }
    
    @classmethod
    def from_dict(cls, data):
        return cls(
            id=data.get('id'),
            question=data.get('question'),
            answer=data.get('answer')
        )