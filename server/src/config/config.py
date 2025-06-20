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
    DEBUG: bool = os.getenv('DEBUG', 'False').lower() == 'true'  # 🔧 Changed to False by default
    PORT: int = int(os.getenv('PORT', 3000))
    LOG_LEVEL: str = os.getenv('LOG_LEVEL', 'INFO')  # 🔧 Changed from DEBUG to INFO
    
    # LLM Service configuration
    LLM_MODEL: str = os.getenv('LLM_MODEL', 'gemini-2.0-flash')
    LLM_TIMEOUT: int = int(os.getenv('LLM_TIMEOUT', 60))  # seconds
    LLM_MAX_TOKENS: int = int(os.getenv('LLM_MAX_TOKENS', 500))
    LLM_TEMPERATURE: float = float(os.getenv('LLM_TEMPERATURE', 0.2))
    
    # API Keys
    GOOGLE_API_KEY: str = os.getenv('GOOGLE_API_KEY', '')
    
    # Database settings (NEW for Task 2.2)
    SUPABASE_URL: str = os.getenv('SUPABASE_URL', '')
    SUPABASE_ANON_KEY: str = os.getenv('SUPABASE_ANON_KEY', '')
    DB_POOL_SIZE: int = int(os.getenv('DB_POOL_SIZE', 20))
    DB_TIMEOUT: int = int(os.getenv('DB_TIMEOUT', 30))
    
    # CORS settings - Smart environment-based configuration
    @classmethod
    def get_cors_origins(cls) -> list:
        """
        Get CORS origins from environment variable with smart defaults.
        
        Supports multiple formats:
        - Comma-separated: "origin1,origin2,origin3"
        - Space-separated: "origin1 origin2 origin3"
        - Mixed: "origin1, origin2 origin3"
        
        Returns:
            list: List of allowed origins, never returns wildcard for security
        """
        origins_str = os.getenv(
            'CORS_ORIGINS', 
            'http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000'
        )
        
        # Handle wildcard case - convert to development defaults for security
        if origins_str.strip() == '*':
            origins_str = 'http://localhost:3000,http://localhost:8080,http://127.0.0.1:3000'
        
        # Parse multiple separators (comma, space, or both)
        origins = []
        for origin in origins_str.replace(' ', ',').split(','):
            clean_origin = origin.strip()
            if clean_origin and clean_origin != '*':  # Security: never allow wildcard
                origins.append(clean_origin)
        
        return origins if origins else ['http://localhost:3000']  # Fallback for safety
    
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
    def validate_environment(cls) -> Dict[str, Any]:
        """
        Comprehensive environment validation with detailed reporting.
        
        Returns:
            dict: Validation results with status, missing variables, and warnings
        """
        validation_result = {
            'valid': True,
            'missing_critical': [],
            'missing_optional': [],
            'warnings': [],
            'environment_summary': {}
        }
        
        # Critical variables (deployment will fail without these)
        critical_vars = {
            'GOOGLE_API_KEY': os.getenv('GOOGLE_API_KEY', ''),
            'LLM_MODEL': os.getenv('LLM_MODEL', ''),
        }
        
        # Optional variables with defaults
        optional_vars = {
            'PORT': os.getenv('PORT'),
            'DEBUG': os.getenv('DEBUG'),
            'LOG_LEVEL': os.getenv('LOG_LEVEL'),
            'LLM_TIMEOUT': os.getenv('LLM_TIMEOUT'),
            'LLM_MAX_TOKENS': os.getenv('LLM_MAX_TOKENS'),
            'LLM_TEMPERATURE': os.getenv('LLM_TEMPERATURE'),
            'SUPABASE_URL': os.getenv('SUPABASE_URL'),
            'SUPABASE_ANON_KEY': os.getenv('SUPABASE_ANON_KEY'),
            'DB_POOL_SIZE': os.getenv('DB_POOL_SIZE'),
            'DB_TIMEOUT': os.getenv('DB_TIMEOUT'),
            'LLM_TEMPERATURE': os.getenv('LLM_TEMPERATURE'),
            'DB_URL': os.getenv('DB_URL'),
        }
        
        # Check critical variables
        for var_name, var_value in critical_vars.items():
            if not var_value or (isinstance(var_value, str) and var_value.strip() == ''):
                validation_result['missing_critical'].append(var_name)
                validation_result['valid'] = False
            else:
                validation_result['environment_summary'][var_name] = "CONFIGURED"
        
        # Check optional variables (warnings only)
        for var_name, var_value in optional_vars.items():
            if var_value is None:
                # Get the default value from class attributes
                default_value = getattr(cls, var_name, 'None')
                validation_result['missing_optional'].append(f"{var_name} (using default: {default_value})")
                validation_result['environment_summary'][var_name] = f"DEFAULT: {default_value}"
            else:
                validation_result['environment_summary'][var_name] = f"SET: {var_value}"
        
        # CORS validation
        cors_origins = cls.get_cors_origins()
        validation_result['environment_summary']['CORS_ORIGINS'] = f"CONFIGURED: {len(cors_origins)} origins"
        
        # Security warnings
        if os.getenv('DEBUG', 'False').lower() == 'true' and os.getenv('ENV', 'development') == 'production':
            validation_result['warnings'].append("DEBUG=True in production environment")
        
        if '*' in str(os.getenv('CORS_ORIGINS', '')):
            validation_result['warnings'].append("Wildcard CORS detected (converted to safe defaults)")
        
        return validation_result
    
    @classmethod
    def log_environment_summary(cls) -> None:
        """Log environment configuration summary at startup."""
        validation = cls.validate_environment()
        
        logger = logging.getLogger(__name__)
        logger.info("🔧 Environment Configuration Summary:")
        
        # Log environment variables
        for var_name, status in validation['environment_summary'].items():
            logger.info(f"   {var_name}: {status}")
        
        # Log warnings
        if validation['warnings']:
            logger.warning("⚠️ Environment Warnings:")
            for warning in validation['warnings']:
                logger.warning(f"   - {warning}")
        
        # Log missing variables
        if validation['missing_critical']:
            logger.error("❌ Missing Critical Variables:")
            for var in validation['missing_critical']:
                logger.error(f"   - {var}")
        
        if validation['missing_optional']:
            logger.info("📝 Using Default Values:")
            for var in validation['missing_optional']:
                logger.info(f"   - {var}")
        
        # Overall status
        if validation['valid']:
            logger.info("✅ Environment configuration is valid for deployment")
        else:
            logger.error("❌ Environment configuration has critical issues")
        
        return validation['valid']
    
    @classmethod
    def configure_logging(cls) -> None:
        """Configure logging for the application."""
        logging_config = cls.get_logging_config()
        logging.config.dictConfig(logging_config)

# Create a config instance
config = AppConfig()
