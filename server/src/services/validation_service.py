"""
Data validation service for category and question integrity.
Ensures data consistency between categories and questions.
"""
import logging
from typing import List, Dict, Any, Set
from datetime import datetime
from dataclasses import dataclass

from ..models.default_data import DefaultCategoryResponse, DefaultInterviewQuestionResponse

logger = logging.getLogger(__name__)

@dataclass
class ValidationResult:
    """Container for validation results with errors, warnings, and statistics."""
    is_valid: bool = True
    errors: List[str] = None
    warnings: List[str] = None
    statistics: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.errors is None:
            self.errors = []
        if self.warnings is None:
            self.warnings = []
        if self.statistics is None:
            self.statistics = {}
    
    def add_error(self, message: str):
        """Add an error message and mark result as invalid."""
        self.errors.append(message)
        self.is_valid = False
    
    def add_warning(self, message: str):
        """Add a warning message."""
        self.warnings.append(message)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert validation result to dictionary."""
        return {
            'is_valid': self.is_valid,
            'errors': self.errors,
            'warnings': self.warnings,
            'statistics': self.statistics,
            'timestamp': datetime.now().isoformat()
        }

class CategoryValidationService:
    """Service for validating category and question data integrity."""
    
    @staticmethod
    async def validate_category_data(categories: List[DefaultCategoryResponse]) -> ValidationResult:
        """Validate category data structure and integrity."""
        result = ValidationResult()
        
        if not categories:
            result.add_error("No categories provided for validation")
            return result
        
        # Check for required fields
        for i, category in enumerate(categories):
            if not category.id:
                result.add_error(f"Category at index {i} missing ID")
            if not category.name:
                result.add_error(f"Category {category.id} missing name")
            if not category.subtopics:
                result.add_warning(f"Category {category.id} has no subtopics")
            elif len(category.subtopics) == 0:
                result.add_warning(f"Category {category.id} has empty subtopics list")
        
        # Check for duplicates
        ids = [cat.id for cat in categories if cat.id]
        names = [cat.name for cat in categories if cat.name]
        
        if len(ids) != len(set(ids)):
            duplicate_ids = [id for id in ids if ids.count(id) > 1]
            result.add_error(f"Duplicate category IDs found: {set(duplicate_ids)}")
        
        if len(names) != len(set(names)):
            duplicate_names = [name for name in names if names.count(name) > 1]
            result.add_warning(f"Duplicate category names found: {set(duplicate_names)}")
        
        # Statistical analysis
        total_subtopics = sum(len(cat.subtopics) for cat in categories if cat.subtopics)
        avg_subtopics = total_subtopics / len(categories) if categories else 0
        
        result.statistics = {
            'total_categories': len(categories),
            'total_subtopics': total_subtopics,
            'avg_subtopics_per_category': round(avg_subtopics, 2),
            'categories_without_subtopics': len([cat for cat in categories if not cat.subtopics]),
            'unique_ids': len(set(ids)),
            'unique_names': len(set(names))
        }
        
        # Quality checks
        if avg_subtopics < 2:
            result.add_warning(f"Low average subtopics per category: {avg_subtopics:.1f}")
        
        if len(categories) < 5:
            result.add_warning(f"Low category count: {len(categories)} (expected 6+)")
        
        return result
    @staticmethod
    async def validate_question_category_mapping(
        questions: List[DefaultInterviewQuestionResponse], 
        categories: List[DefaultCategoryResponse]
    ) -> ValidationResult:
        """Validate integrity between questions and categories."""
        result = ValidationResult()
        
        if not questions:
            result.add_warning("No questions provided for validation")
            return result
        
        if not categories:
            result.add_error("No categories provided for mapping validation")
            return result
        
        # Get all valid category IDs and subtopics
        valid_category_ids = {cat.id for cat in categories if cat.id}
        valid_subtopics = set()
        for cat in categories:
            if cat.subtopics:
                valid_subtopics.update(cat.subtopics)
        
        # Check question-category relationships
        orphaned_questions = []
        invalid_subtopics = []
        category_question_count = {}
        
        for question in questions:
            # Check category_id field (primary)
            if hasattr(question, 'category_id') and question.category_id:
                if question.category_id not in valid_category_ids:
                    orphaned_questions.append(f"Question {question.id} has invalid category_id: {question.category_id}")
                else:
                    category_question_count[question.category_id] = category_question_count.get(question.category_id, 0) + 1
            
            # Check fallback category field
            elif question.category and question.category not in valid_category_ids:
                orphaned_questions.append(f"Question {question.id} has invalid category: {question.category}")
            
            # Check subtopic validity
            if question.subtopic and question.subtopic not in valid_subtopics:
                invalid_subtopics.append(f"Question {question.id} has invalid subtopic: {question.subtopic}")
        
        # Report issues
        if orphaned_questions:
            result.add_error(f"Found {len(orphaned_questions)} questions with invalid categories")
        
        if invalid_subtopics:
            result.add_warning(f"Found {len(invalid_subtopics)} questions with invalid subtopics")
        
        # Check for empty categories
        categories_with_questions = set(category_question_count.keys())
        empty_categories = valid_category_ids - categories_with_questions
        if empty_categories:
            result.add_warning(f"Categories with no questions: {empty_categories}")
        
        # Statistical analysis
        result.statistics = {
            'total_questions': len(questions),
            'valid_categories': len(valid_category_ids),
            'valid_subtopics': len(valid_subtopics),
            'orphaned_questions': len(orphaned_questions),
            'invalid_subtopics': len(invalid_subtopics),
            'empty_categories': len(empty_categories),
            'category_question_distribution': category_question_count,
            'avg_questions_per_category': len(questions) / len(valid_category_ids) if valid_category_ids else 0
        }
        
        return result

    @staticmethod
    async def validate_question_quality(questions: List[DefaultInterviewQuestionResponse]) -> ValidationResult:
        """Validate question content quality and completeness."""
        result = ValidationResult()
        
        if not questions:
            result.add_warning("No questions provided for quality validation")
            return result
        
        # Quality checks
        missing_text = [q.id for q in questions if not q.text or len(q.text.strip()) < 10]
        missing_answers = [q.id for q in questions if not q.answer or len(q.answer.strip()) < 10]
        missing_difficulty = [q.id for q in questions if not q.difficulty]
        missing_subtopic = [q.id for q in questions if not q.subtopic]
        
        # Length analysis
        short_questions = [q.id for q in questions if q.text and len(q.text.strip()) < 20]
        short_answers = [q.id for q in questions if q.answer and len(q.answer.strip()) < 30]
        
        # Difficulty distribution
        difficulty_counts = {}
        for q in questions:
            if q.difficulty:
                difficulty_counts[q.difficulty] = difficulty_counts.get(q.difficulty, 0) + 1
        
        # Report issues
        if missing_text:
            result.add_error(f"Questions with missing/short text: {len(missing_text)}")
        
        if missing_answers:
            result.add_warning(f"Questions with missing/short answers: {len(missing_answers)}")
        
        if missing_difficulty:
            result.add_warning(f"Questions missing difficulty: {len(missing_difficulty)}")
        
        if missing_subtopic:
            result.add_warning(f"Questions missing subtopic: {len(missing_subtopic)}")
        
        if short_questions:
            result.add_warning(f"Questions with very short text: {len(short_questions)}")
        
        result.statistics = {
            'total_questions': len(questions),
            'missing_text': len(missing_text),
            'missing_answers': len(missing_answers),
            'missing_difficulty': len(missing_difficulty),
            'missing_subtopic': len(missing_subtopic),
            'short_questions': len(short_questions),
            'short_answers': len(short_answers),
            'difficulty_distribution': difficulty_counts,
            'avg_question_length': sum(len(q.text) for q in questions if q.text) / len(questions),
            'avg_answer_length': sum(len(q.answer) for q in questions if q.answer) / len([q for q in questions if q.answer])
        }
        
        return result

def generate_improvement_recommendations(
    category_validation: ValidationResult, 
    mapping_validation: ValidationResult
) -> List[str]:
    """Generate actionable recommendations based on validation results."""
    recommendations = []
    
    # Category recommendations
    if category_validation.statistics.get('total_categories', 0) < 6:
        recommendations.append("Add more categories to reach the expected 6+ UI categories")
    
    if category_validation.statistics.get('avg_subtopics_per_category', 0) < 2:
        recommendations.append("Increase subtopic variety within categories")
    
    if category_validation.statistics.get('categories_without_subtopics', 0) > 0:
        recommendations.append("Add subtopics to categories that are missing them")
    
    # Mapping recommendations
    if mapping_validation.statistics.get('orphaned_questions', 0) > 0:
        recommendations.append("Fix questions with invalid category references")
    
    if mapping_validation.statistics.get('empty_categories', 0) > 0:
        recommendations.append("Add questions to categories that have no content")
    
    if mapping_validation.statistics.get('avg_questions_per_category', 0) < 5:
        recommendations.append("Increase question variety per category (target: 5+ questions each)")
    
    # Quality recommendations
    if not recommendations:
        recommendations.append("Data validation passed - system is operating optimally")
    
    return recommendations
