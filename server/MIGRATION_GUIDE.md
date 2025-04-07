# Flask to FastAPI Migration Guide

This document outlines the changes made to migrate the Flashcard Grading application from Flask to FastAPI.

## Key Changes

### 1. Project Structure

The overall structure remains similar, but with these key changes:
- `app.py` → `main.py` (FastAPI entry point)
- Added Pydantic models in `src/models/schema.py`
- Updated routes to use FastAPI's router system
- Enhanced error handling with FastAPI's exception system

### 2. Core Components

#### FastAPI Application (main.py)
- Created a FastAPI instance instead of Flask
- Used FastAPI's built-in CORS middleware instead of Flask-CORS
- Added middleware for request/response logging
- Setup routing using FastAPI's include_router
- Uses Uvicorn as the ASGI server instead of Flask's built-in server

#### Pydantic Models (schema.py)
- Added request/response models with validation
- Models define expected data structure for API requests and responses
- Automatic validation prevents malformed requests from reaching route handlers

#### API Routes (grading_routes.py)
- Converted Flask blueprint to FastAPI router
- Used dependency injection for controllers
- Added response_model annotations for automatic validation
- Structured error handling using HTTPException
- Enhanced input validation with Pydantic

#### LLM Service
- Enhanced error handling and validation
- Improved JSON parsing with regex for better handling of LLM responses
- Added validation method to ensure responses have the expected structure
- Maintained the async/await pattern that works well with FastAPI

### 3. Key Benefits of FastAPI

- **Automatic documentation**: Visit `/docs` or `/redoc` for interactive API documentation
- **Request/Response validation**: Automatic validation based on Pydantic models
- **Dependency injection**: Clean, testable code with Depends()
- **Native async support**: Better performance for I/O-bound operations
- **Type checking**: Improved development experience with static type checking
- **Better error handling**: Structured error responses with HTTPException

## Running the Application

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the application:
   ```bash
   python main.py
   ```
   
   Or using Uvicorn directly:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 5000
   ```

3. Access the API documentation:
   - Swagger UI: http://localhost:5000/docs
   - ReDoc: http://localhost:5000/redoc

## Testing

Run tests using pytest:
```bash
pytest test_api_endpoint.py -v
```

## Migration Best Practices Applied

1. **Typed Data**: Using Pydantic models for data validation
2. **Dependency Injection**: Using Depends() for resource management
3. **Clean Architecture**: Maintaining separation between routes, controllers, and services
4. **Error Handling**: Structured error responses with appropriate status codes
5. **Async Support**: Leveraging FastAPI's native async capabilities
6. **Documentation**: Auto-generated API documentation
7. **Testing**: Enhanced testing with TestClient
