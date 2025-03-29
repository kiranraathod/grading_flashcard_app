import os
import psycopg2
import psycopg2.extras
import logging
from psycopg2.pool import SimpleConnectionPool
from contextlib import contextmanager
from dotenv import load_dotenv

# Set up logger
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '..', '.env.local'))

# Connection pool
pool = None

def init_db_pool():
    """Initialize the database connection pool"""
    global pool
    
    if pool is not None:
        return
        
    # Get database connection details
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("DB_NAME", "flashcards")
    db_user = os.getenv("DB_USER", "postgres")
    db_password = os.getenv("DB_PASSWORD", "password")
    
    logger.info(f"Initializing DB pool for {db_host}:{db_port}/{db_name}")
    
    # Create connection pool
    try:
        pool = SimpleConnectionPool(
            minconn=1,
            maxconn=10,
            host=db_host,
            port=db_port,
            dbname=db_name,
            user=db_user,
            password=db_password
        )
        logger.info("Database connection pool initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database pool: {str(e)}")
        raise

@contextmanager
def get_db_cursor():
    """Get a database cursor from the pool"""
    global pool
    
    if pool is None:
        init_db_pool()
        
    conn = pool.getconn()
    conn.autocommit = False
    
    try:
        # Use RealDictCursor to get dict-like results
        yield conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
        conn.commit()
    except Exception as e:
        logger.error(f"Database error: {str(e)}")
        conn.rollback()
        raise
    finally:
        pool.putconn(conn)

def get_connection():
    """Get a raw connection from the pool"""
    global pool
    
    if pool is None:
        init_db_pool()
        
    return pool.getconn()

def return_connection(conn):
    """Return a connection to the pool"""
    global pool
    
    if pool is not None:
        pool.putconn(conn)
