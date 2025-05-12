# Flashcard LLM API
A Flask-based API for grading flashcard answers using LLM technology.

## Overview
This project provides an API for grading user answers to flashcard questions, generating study suggestions, and collecting user feedback. It leverages natural language processing to evaluate the quality and correctness of user responses to flashcards.

## Features
- **Answer Grading**: Evaluate user answers to flashcard questions
- **Study Suggestions**: Generate personalized study suggestions based on user performance
- **Feedback Collection**: Collect and process user feedback to improve the system

## Setup
1. Clone the repository
2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
3. Create a `.env` file based on the provided `.env.example`:
   ```
   cp .env.example .env
   ```
4. Update the `.env` file with your actual API keys and configuration
5. Run the application:
   ```
   python app.py
   ```

## Environment Configuration
- `DEBUG`: Enable debug mode (True/False)
- `PORT`: Port number to run the API on
- `FLASK_ENV`: Environment (development/production)
- `LLM_MODEL`: LLM model to use for grading
- `GOOGLE_API_KEY`: Your Google API key for Gemini model access
- `ALLOWED_ORIGINS`: Comma-separated list of allowed CORS origins

## API Endpoints
- `GET /`: Health check endpoint
- `POST /api/grade`: Grade a flashcard answer
- `GET /api/suggestions`: Get study suggestions
- `POST /api/feedback`: Submit user feedback

## Security Notes
- Never commit your `.env` file with real API keys
- In production, use a proper secrets management solution
- Configure CORS settings appropriately for your deployment environment