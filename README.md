# Flashcard App with Local PostgreSQL

This project is a flashcard application with a Flutter frontend and a Python Flask backend. It uses a local PostgreSQL database running in Docker to store user data, flashcards, and learning progress.

## Prerequisites

- Docker and Docker Compose
- Flutter SDK (3.7.2 or higher)
- Python 3.9 or higher
- Git

## Getting Started

Follow these steps to set up and run the application:

### 1. Start the PostgreSQL Database

```bash
# From the project root directory
docker-compose up -d
```

This will start both the PostgreSQL database and pgAdmin for database management.

- PostgreSQL will be available at `localhost:5432`
- pgAdmin will be available at `localhost:5050` (login with admin@example.com / admin)

### 2. Set Up the Server

```bash
# From the project root directory
cd server

# Create a virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run the server
python app.py
```

The server will start on `localhost:5000`.

### 3. Run the Flutter App

```bash
# From the project root directory
cd client

# Get Flutter dependencies
flutter pub get

# Run the app
flutter run
```

## Features

- **User Authentication**: Register, login, and password reset
- **Flashcard Management**: Create, edit, and delete flashcard sets
- **Study Mode**: Study flashcards with self-assessment
- **Spaced Repetition**: Smart scheduling of card reviews based on performance
- **Progress Tracking**: Track learning progress and statistics

## Architecture

### Backend (Flask)

- **Authentication Service**: Handles JWT-based authentication
- **PostgreSQL Service**: Interacts with the local PostgreSQL database
- **API Endpoints**: RESTful endpoints for all application features

### Frontend (Flutter)

- **Local Auth Service**: Handles JWT token management and authentication state
- **Local API Service**: Interacts with the backend API
- **User Service**: Manages user data and state
- **Flashcard Service**: Manages flashcard data and state

### Database (PostgreSQL)

- **Tables**:
  - `users`: User accounts
  - `profiles`: User profiles
  - `flashcard_sets`: Sets of flashcards
  - `flashcards`: Individual flashcards
  - `study_sessions`: User study sessions
  - `flashcard_grades`: Grades for answered cards
  - `user_feedback`: User feedback on card grading
  - `user_progress`: User progress tracking for spaced repetition

## Alternative Setup (Without Docker)

If you prefer not to use Docker, you can set up PostgreSQL directly:

1. Download and install PostgreSQL from the [official website](https://www.postgresql.org/download/)
2. Create a database named "flashcards"
3. Set your PostgreSQL username and password in `.env.local`
4. Run the SQL scripts from `server/db/init` to create the schema

## License

[MIT License](LICENSE)
