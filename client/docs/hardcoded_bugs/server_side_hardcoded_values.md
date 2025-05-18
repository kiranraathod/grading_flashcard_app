# Server-Side Hardcoded Values Analysis

## Overview

This document analyzes hardcoded values in the server-side Python code of the FlashMaster application. Server-side hardcoded values include static constants, fixed thresholds, error messages, and configuration settings embedded directly in the code that should ideally be externalized or made configurable.

## Categories of Server-Side Hardcoded Values

The server-side code contains several categories of hardcoded values:

1. **LLM Prompts**
2. **Error Messages and Response Templates**
3. **Fixed Thresholds and Constants**
4. **Default Configuration Values**
5. **Fallback Values and Recovery Logic**
6. **Regular Expression Patterns**

## 1. LLM Prompts

### Description
Large Language Model (LLM) prompts hardcoded directly in the service classes, defining how the application interacts with the Google Gemini model.

### Key Findings

#### 1.1 Answer Grading Prompt

**File:** `src/services/llm_service.py`

```python
prompt = f"""
You are a precise, helpful, and encouraging grading assistant. You will evaluate a student's answer against the correct answer provided on a flashcard.

Question: {question}

Correct Answer: {correct_answer}

Student's Answer: {user_answer}

GRADING INSTRUCTIONS:
1. Consider semantic equivalence - if the student's answer conveys the same meaning as the correct answer, it should be considered correct even if phrased differently.
2. Ignore minor differences in capitalization, punctuation, and formatting unless they change the meaning.
3. For mathematical answers, accept equivalent forms (e.g., "1/2" and "0.5" are equivalent).
4. For factual answers, focus on the key concepts rather than exact wording.

GRADING SCALE:
- A: The answer is completely correct or semantically equivalent to the correct answer.
- B: The answer is mostly correct with minor omissions or inaccuracies (80-90% correct).
- C: The answer shows partial understanding but has significant gaps (70-80% correct).
- D: The answer shows minimal understanding with major errors (60-70% correct).
- F: The answer is completely incorrect or shows fundamental misunderstanding (<60% correct).

When providing feedback, be specific about the comparison between the student's answer and the correct answer. Always include encouraging language, even for incorrect answers.

When referring to mathematical formulas, use simple text notation like "pi*r^2" for πr² to avoid encoding issues.
Also, avoid using * instead of × for multiplication.

Your response must strictly conform to this JSON format:
{
    "grade": "LETTER",
    "feedback": "DETAILED_FEEDBACK",
    "suggestions": ["SUGGESTION_1", "SUGGESTION_2", "SUGGESTION_3"]
}

Where:
- LETTER must be a single letter grade (A, B, C, D, or F) based on how well the student's answer matches the correct answer
- DETAILED_FEEDBACK must include specific comparison to the correct answer and encouragement
- There must be 2-3 specific suggestions in the suggestions array that help the student improve

For excellent answers (grade A), provide suggestions that extend the student's knowledge.
For other grades, provide targeted suggestions to help improve understanding of the concept.

Do not include any explanations, markdown formatting or any text outside the JSON structure.
Return only the valid JSON object, nothing else.
"""
```

#### 1.2 Interview Grading Prompt

**File:** `src/controllers/interview_grading_controller.py`

```python
def _create_grading_prompt(
    self, 
    question: str, 
    answer: str,
    category: str,
    difficulty: str
) -> str:
    """Create a custom prompt for the LLM to grade an interview answer."""
    # Base prompt with instructions for the LLM
    base_prompt = f"""
    You are an expert interviewer and evaluator specialized in {category} interviews.
    
    Please evaluate the following answer to an interview question. 
    The question is categorized as "{category}" with a difficulty level of "{difficulty}".
    
    QUESTION:
    {question}
    
    CANDIDATE'S ANSWER:
    {answer}
    
    EVALUATION INSTRUCTIONS:
    1. Evaluate the answer based on completeness, accuracy, clarity, and depth.
    2. Provide a numerical score from 0 to 100.
    3. Give specific, constructive feedback on the answer.
    4. Provide 3-5 suggestions for improvement.
    5. DO NOT repeat or reveal what a perfect or ideal answer would be.
    
    Your response must strictly conform to this JSON format:
    {
        "score": <numerical_score>,
        "feedback": "<detailed_feedback>",
        "suggestions": ["<suggestion_1>", "<suggestion_2>", ...]
    }
    
    Where:
    - numerical_score must be an integer between 0 and 100
    - detailed_feedback must include specific evaluation and encouragement
    - There must be 3-5 specific suggestions in the suggestions array
    
    Do not include any explanations, markdown formatting or any text outside the JSON structure.
    Return only the valid JSON object, nothing else.
    """
```

#### 1.3 Job Description Analysis Prompt

**File:** `src/services/job_description_service.py`

```python
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
```

### Impact

- **Prompt Optimization Issues**: Improving LLM prompts requires code changes
- **Lack of Versioning**: No way to track or version prompt changes
- **Consistency Problems**: Hard to ensure consistent prompt structure across different services
- **Testing Difficulty**: Testing prompt variations requires code changes

## 2. Error Messages and Response Templates

### Description
Hardcoded error messages, default responses, and fallback templates embedded in the code.

### Key Findings

#### 2.1 Fixed Error Messages

**File:** `src/controllers/grading_controller.py`

```python
error_responses = {
    "llm_connection_error": {
        'grade': 'X',  # Use 'X' to indicate system error
        'feedback': f'LLM Service Error: {message}',
        'suggestions': [
            'The AI grading service is currently unavailable',
            'Please try again later or contact system administrator',
            'Verify your internet connection and API credentials'
        ],
        'error': error_type
    },
    "llm_response_error": {
        'grade': 'X',
        'feedback': f'Error processing your answer: {message}',
        'suggestions': [
            'Please try a different wording in your answer',
            'If this error persists, contact support'
        ],
        'error': error_type
    },
    # ... more error responses
}
```

#### 2.2 Default Suggestions

**File:** `src/controllers/grading_controller.py`

```python
# If no cached suggestions, provide generic ones
suggestions = [
    "Try to be more specific in your answer",
    "Review the key concepts related to this topic",
    "Practice recalling this information regularly"
]
```

#### 2.3 Fallback Response Templates

**File:** `src/controllers/interview_grading_controller.py`

```python
def _create_fallback_response(self, error_message: str) -> Dict[str, Any]:
    """Create a fallback response when LLM grading fails."""
    logger.warning(f"Creating fallback response due to: {error_message}")
    
    return {
        "score": 50,  # Neutral score
        "feedback": f"We couldn't properly analyze your answer. {error_message}",
        "suggestions": [
            "Review the key concepts related to this topic",
            "Try to be more specific in your answer",
            "Structure your response more clearly",
            "Please try again later when our service is fully operational"
        ]
    }
```

### Impact

- **Localization Challenges**: Fixed error messages cannot be easily translated
- **Inconsistent Messaging**: Error messages may not align with application UI
- **Limited Customization**: No way to customize messages for different users or contexts

## 3. Fixed Thresholds and Constants

### Description
Hardcoded numeric thresholds, timeouts, and operational constants.

### Key Findings

#### 3.1 LLM Temperature Settings

**File:** `src/services/llm_service.py`

```python
# Setup the model with slightly higher temperature for more creative feedback
interview_temperature = max(self.temperature, 0.3)  # Minimum 0.3 temperature for interviews
```

**File:** `src/services/job_description_service.py`

```python
model = self.llm_service.client.GenerativeModel(
    self.llm_service.model,
    generation_config={
        "temperature": 0.2,  # Lower temperature for more focused analysis
        "max_output_tokens": 2048
    }
)
```

#### 3.2 Retry and Timeout Constants

**File:** `src/services/job_description_service.py`

```python
# Default value for the max_retries parameter
max_retries: int = 2

# Fixed timeout values
timeout=self.llm_service.timeout
```

#### 3.3 Grade Thresholds

**File:** `src/services/llm_service.py`

```python
# Hardcoded in the grading prompt
"""
GRADING SCALE:
- A: The answer is completely correct or semantically equivalent to the correct answer.
- B: The answer is mostly correct with minor omissions or inaccuracies (80-90% correct).
- C: The answer shows partial understanding but has significant gaps (70-80% correct).
- D: The answer shows minimal understanding with major errors (60-70% correct).
- F: The answer is completely incorrect or shows fundamental misunderstanding (<60% correct).
"""
```

### Impact

- **Performance Tuning Challenges**: Adjusting thresholds requires code changes
- **Environment-Specific Issues**: Cannot easily adjust for different environments
- **Testing Limitations**: Testing different thresholds requires code modifications

## 4. Default Configuration Values

### Description
Default values for configuration settings when environment variables are not set.

### Key Findings

#### 4.1 Default Service Configuration

**File:** `src/config/config.py`

```python
class AppConfig:
    """Application configuration class."""
    
    # Server configuration
    DEBUG: bool = os.getenv('DEBUG', 'True').lower() == 'true'
    PORT: int = int(os.getenv('PORT', 3000))
    LOG_LEVEL: str = os.getenv('LOG_LEVEL', 'DEBUG')
    
    # LLM Service configuration
    LLM_MODEL: str = os.getenv('LLM_MODEL', 'gemini-2.0-flash')
    LLM_TIMEOUT: int = int(os.getenv('LLM_TIMEOUT', 60))  # seconds
    LLM_MAX_TOKENS: int = int(os.getenv('LLM_MAX_TOKENS', 500))
    LLM_TEMPERATURE: float = float(os.getenv('LLM_TEMPERATURE', 0.2))
```

#### 4.2 Logging Configuration

**File:** `src/config/config.py`

```python
# In the get_logging_config method
'maxBytes': 10485760,  # 10MB
'backupCount': 10,
```

#### 4.3 CORS Configuration

**File:** `main.py`

```python
# Configure CORS based on settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=config.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],  # Can be restricted in production
    allow_headers=["*"],  # Can be restricted in production
    expose_headers=["*"],  # Can be restricted in production
)
```

### Impact

- **Environment Consistency**: Default values may not be suitable for all environments
- **Security Implications**: Overly permissive defaults (like CORS settings)
- **Operational Challenges**: Difficult to adjust configuration for different operational scenarios

## 5. Fallback Values and Recovery Logic

### Description
Hardcoded fallback responses and recovery mechanisms when operations fail.

### Key Findings

#### 5.1 Default Return Values on Error

**File:** `src/services/job_description_service.py`

```python
# Return a simplified result if parsing fails
return {
    "required_skills": [],
    "desired_skills": [],
    "experience_level": "mid",
    "domain_knowledge": [],
    "soft_skills": [],
    "technologies": []
}
```

#### 5.2 Default Suggestions When Missing

**File:** `src/services/llm_service.py`

```python
# If suggestions array is empty, add default suggestions based on grade
if len(response['suggestions']) == 0:
    logger.warning("Empty suggestions array detected, adding default suggestions")
    if response['grade'] == 'A':
        response['suggestions'] = [
            "Continue practicing to maintain your understanding",
            "Try applying this knowledge to more complex problems",
            "Consider exploring related topics to deepen your understanding"
        ]
    else:
        response['suggestions'] = [
            "Review the core concepts related to this topic",
            "Practice with similar problems to reinforce your understanding",
            "Consider creating additional flashcards on this subject"
        ]
```

### Impact

- **Unexpected Behavior**: Users may not realize fallback values are being used
- **Data Consistency Issues**: Fallback data may not be consistent with user expectations
- **Debug Difficulty**: Hard to identify when fallback values are being used

## 6. Regular Expression Patterns

### Description
Hardcoded regular expression patterns used for parsing and data cleaning.

### Key Findings

#### 6.1 JSON Extraction Patterns

**File:** `src/services/llm_service.py`

```python
# Clean up the content - handle various response formats
# Remove markdown code blocks if present
if '```json' in content:
    content = re.search(r'```json\s*(.*?)\s*```', content, re.DOTALL)
    if content:
        content = content.group(1)
elif '```' in content:
    content = re.search(r'```\s*(.*?)\s*```', content, re.DOTALL)
    if content:
        content = content.group(1)
```

#### 6.2 Mathematical Symbol Replacement Patterns

**File:** `src/services/llm_service.py`

```python
# Fix common mathematical patterns with regex
patterns = {
    r'πr²|πr\^2|pir²|pir\^2|Ïr²|ÏrÂ²': 'pi*r^2',
    r'a²\+b²|aÂ²\+bÂ²': 'a^2+b^2',
}
```

#### 6.3 JSON Cleaning Patterns

**File:** `src/services/job_description_service.py`

```python
# Clean control characters from the JSON response
import re
# Replace all control characters except \n and \r with spaces
response_text = re.sub(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f]', ' ', response_text)
# Normalize whitespace
response_text = re.sub(r'\s+', ' ', response_text)
```

### Impact

- **Maintenance Challenges**: Regex patterns need to be updated as LLM output changes
- **Error Handling Issues**: Regex failures may not be handled properly
- **Testing Complexity**: Difficult to test all possible pattern variations

## Analysis of File Distribution

The server-side hardcoded values are primarily concentrated in the following files:

1. **llm_service.py**: Contains LLM prompts, grading criteria, and parsing logic
2. **grading_controller.py**: Includes error messages, response templates, and fallback mechanisms
3. **job_description_service.py**: Contains analysis prompts, generation prompts, and parsing patterns
4. **config.py**: Has default configuration values and logging settings
5. **interview_grading_controller.py**: Includes interview-specific prompts and response templates

## Key Issues and Risks

### 1. Limited Configurability

The extensive use of hardcoded values limits the ability to configure the application for different environments, users, or use cases without code changes.

### 2. Prompt Optimization Barriers

The hardcoded LLM prompts make it difficult to optimize or update the prompts based on feedback or performance metrics without code changes.

### 3. Localization Challenges

Fixed error messages and response templates are not designed for localization, making it difficult to support multiple languages.

### 4. Deployment Complexity

Environment-specific values hardcoded in the server code make deployment to different environments more complex.

### 5. Testing Limitations

Hardcoded values make it difficult to test different configurations or scenarios without modifying the code.

## Recommendations

### 1. Externalize LLM Prompts

**Priority: High**

- Move LLM prompts to external template files
- Implement a template engine with variable substitution
- Create a prompt management system for versioning and optimization

```python
# Before
prompt = f"""You are a precise, helpful, and encouraging grading assistant..."""

# After
from src.utils.prompt_manager import get_prompt
prompt = get_prompt("grading_template", 
                   {"question": question, "correct_answer": correct_answer, "user_answer": user_answer})
```

### 2. Create Message Catalogs

**Priority: High**

- Extract all error messages and response templates to a centralized message catalog
- Support localization of messages
- Add context-specific message variants

```python
# Before
return {
    "score": 50,
    "feedback": f"We couldn't properly analyze your answer. {error_message}",
    "suggestions": ["Review the key concepts...", "Try to be more specific..."]
}

# After
from src.utils.messages import get_message, get_suggestions
return {
    "score": 50,
    "feedback": get_message("analysis_error", {"error": error_message}),
    "suggestions": get_suggestions("analysis_error")
}
```

### 3. Implement Dynamic Configuration

**Priority: Medium**

- Create a hierarchical configuration system
- Support environment-specific configuration overrides
- Add runtime configuration updates

```python
# Before
temperature = max(self.temperature, 0.3)  # Minimum 0.3 temperature for interviews

# After
from src.config.dynamic_config import get_config
temperature = max(self.temperature, get_config("llm.min_interview_temperature"))
```

### 4. Create a Pattern Library

**Priority: Medium**

- Extract regex patterns to a central pattern library
- Add testing for pattern reliability
- Implement pattern versioning

```python
# Before
response_text = re.sub(r'[\x00-\x09\x0b\x0c\x0e-\x1f\x7f]', ' ', response_text)

# After
from src.utils.patterns import apply_pattern
response_text = apply_pattern("clean_control_chars", response_text)
```

### 5. Implement Feature Flags

**Priority: Low**

- Develop a feature flag system for toggling features
- Support gradual rollout of features
- Add experimental feature capabilities

```python
# Before
if self.model == "gemini-2.0-flash":
    # Use special handling for this model
    
# After
from src.utils.feature_flags import is_enabled
if is_enabled("use_enhanced_parsing"):
    # Use enhanced parsing features
```

## Implementation Plan

### 1. Short-Term (1-2 Weeks)

- Extract LLM prompts to external template files
- Create a basic message catalog for error messages
- Implement environment-specific configuration override capabilities

### 2. Medium-Term (2-4 Weeks)

- Develop a prompt management system with versioning
- Extract regex patterns to a pattern library
- Create a feedback loop for prompt optimization

### 3. Long-Term (1-3 Months)

- Implement a full internationalization system
- Develop dynamic configuration updates
- Create a feature flag system
- Build a prompt performance analytics system

## Conclusion

The server-side code of the FlashMaster application contains numerous hardcoded values, particularly in the areas of LLM prompts, error messages, and configuration defaults. These hardcoded values create significant challenges for maintenance, localization, testing, and deployment.

By implementing the recommended changes, particularly externalizing LLM prompts and creating message catalogs, the application can become more flexible, maintainable, and adaptable to different environments and use cases. The implementation plan provides a structured approach to addressing these issues while maintaining continuous functionality of the application.
