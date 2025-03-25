import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    """Base configuration"""
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
    PORT = int(os.getenv('PORT', 5000))
    LLM_PROVIDER = os.getenv('LLM_PROVIDER', 'google')
    LLM_MODEL = os.getenv('LLM_MODEL', 'gemini-pro')
    
    # API keys
    GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
    
    # Validation
    @classmethod
    def validate(cls):
        """Validate that all required configuration is present"""
        if cls.LLM_PROVIDER.lower() == 'google' and not cls.GOOGLE_API_KEY:
            raise ValueError("GOOGLE_API_KEY is required when LLM_PROVIDER is 'google'")
        elif cls.LLM_PROVIDER.lower() == 'openai' and not cls.OPENAI_API_KEY:
            raise ValueError("OPENAI_API_KEY is required when LLM_PROVIDER is 'openai'")
        
        return True

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False

# Dictionary of available configurations
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

# Active configuration
active_config = config[os.getenv('FLASK_ENV', 'default')]