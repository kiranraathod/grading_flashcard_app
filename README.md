# Flutter Flashcard App with LLM Integration

A comprehensive mobile application for flashcard-based learning with intelligent grading powered by Large Language Models.

## Project Overview

This project combines a Flutter mobile application with a custom Python REST API backend that leverages large language models (LLMs) for intelligent answer grading and personalized learning suggestions.

## Features

- **Interactive Flashcards**: Smooth card flip animations and intuitive navigation
- **Dual Input Methods**: Type answers or use speech-to-text functionality
- **LLM-Based Grading**: Submit answers for intelligent evaluation by Large Language Models
- **Personalized Feedback**: Receive actionable feedback and improvement suggestions
- **Cross-Platform Support**: Works on Android, iOS, and web platforms

## Project Structure

The project is divided into two main components:

### 1. Flutter App (Client)

The mobile application that users interact with to practice flashcards.

```
/client
├── lib/
│   ├── models/        # Data structures and state management
│   ├── screens/       # Main application screens
│   ├── services/      # API integration and device services
│   ├── utils/         # Helper functions and constants
│   ├── widgets/       # Reusable UI components
│   └── main.dart      # Application entry point
└── pubspec.yaml       # Flutter dependencies
```

### 2. Python Backend (Server)

REST API that integrates with LLMs for grading and suggestion generation.

```
/server
├── src/
│   ├── config/        # Configuration management
│   ├── controllers/   # Request handlers
│   ├── models/        # Data models
│   ├── routes/        # API endpoint definitions
│   ├── services/      # Business logic and LLM integration
│   └── __init__.py    # Package initialization
├── app.py             # API entry point
├── requirements.txt   # Python dependencies
└── .env.example       # Environment variable template
```

## Setup Instructions

### Client Setup

1. Ensure Flutter is installed on your system (v3.0.0 or higher recommended)
2. Navigate to the client directory:
   ```bash
   cd client
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

### Server Setup

1. Ensure Python 3.8+ is installed on your system
2. Navigate to the server directory:
   ```bash
   cd server
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Create a `.env` file based on the provided template:
   ```bash
   cp .env.example .env
   ```
5. Update the `.env` file with your LLM API keys and configuration
6. Start the server:
   ```bash
   python app.py
   ```

## Environment Configuration

The server requires the following environment variables:
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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
