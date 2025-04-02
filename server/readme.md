# Flashcard Grading App - FastAPI Backend

This is the backend server for the Flashcard Grading application. It provides APIs for grading flashcard responses, managing spaced repetition, and integrating with Supabase.

## Technology Stack

- **FastAPI**: Modern, high-performance web framework for building APIs
- **Uvicorn**: ASGI server for running FastAPI applications
- **Supabase**: Backend-as-a-Service for database, authentication, and storage
- **Google Gemini**: AI language model for grading flashcard responses

## Features

- **Automated Grading**: AI-powered assessment of flashcard answers
- **Spaced Repetition**: SM-2 algorithm implementation for optimized learning
- **Authentication**: JWT-based authentication with Supabase
- **Performance Monitoring**: Request timing and performance tracking

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/grading_flashcard_app.git
   cd grading_flashcard_app/server
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

## Running the Server

```bash
python start.py
```

Or with Uvicorn directly:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 3000
```

## API Documentation

- **Swagger UI**: http://localhost:3000/docs
- **ReDoc**: http://localhost:3000/redoc

## API Endpoints

### Grading API

- `POST /api/grade`: Grade a flashcard answer
- `GET /api/suggestions`: Get improvement suggestions
- `POST /api/feedback`: Submit user feedback on grading

### Spaced Repetition API

- `GET /api/spaced/due-cards`: Get cards due for review
- `POST /api/spaced/update-progress`: Update card progress
- `GET /api/spaced/stats`: Get learning statistics

## Supabase Integration

This application uses Supabase for:
- User authentication and authorization
- Data storage for flashcards and progress
- Session management and secure access

## Development Notes

- The application has been migrated from Flask to FastAPI for improved performance
- Async support is used throughout for better concurrency handling
- All API requests and responses are validated using Pydantic models
