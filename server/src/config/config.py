"""
Centralized configuration management for the application.
"""
import os
from typing import Dict, Any, Optional
from dotenv import load_dotenv
import logging

# Load environment variables from .env file
load_dotenv()

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
    
    # API Keys
    GOOGLE_API_KEY: str = os.getenv('GOOGLE_API_KEY', '')
    
    # CORS settings
    CORS_ORIGINS: list = os.getenv('CORS_ORIGINS', '*').split(',')
    
    # Database settings (for future use)
    DB_URL: str = os.getenv('DB_URL', '')
    
    @classmethod
    def get_logging_config(cls) -> Dict[str, Any]:
        """Get logging configuration."""
        return {
            'version': 1,
            'disable_existing_loggers': False,
            'formatters': {
                'standard': {
                    'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
                },
            },
            'handlers': {
                'console': {
                    'class': 'logging.StreamHandler',
                    'level': cls.LOG_LEVEL,
                    'formatter': 'standard',
                },
                'file': {
                    'class': 'logging.handlers.RotatingFileHandler',
                    'level': cls.LOG_LEVEL,
                    'formatter': 'standard',
                    'filename': 'logs/app.log',
                    'maxBytes': 10485760,  # 10MB
                    'backupCount': 10,
                    'encoding': 'utf8',
                },
            },
            'loggers': {
                '': {  # root logger
                    'handlers': ['console', 'file'],
                    'level': cls.LOG_LEVEL,
                },
                'src': {
                    'handlers': ['console', 'file'],
                    'level': cls.LOG_LEVEL,
                    'propagate': False,
                },
            }
        }
    
    @classmethod
    def validate_config(cls) -> Optional[str]:
        """Validate the configuration and return an error message if invalid."""
        if not cls.GOOGLE_API_KEY:
            return "GOOGLE_API_KEY environment variable is not set"
        return None
    
    @classmethod
    def configure_logging(cls) -> None:
        """Configure logging for the application."""
        logging_config = cls.get_logging_config()
        logging.config.dictConfig(logging_config)

# Create a config instance
config = AppConfig()
