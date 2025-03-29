"""
This script has been replaced with a direct PostgreSQL export/import process.
For historical purposes, this file is kept as a reference.
"""

import os
import logging

logger = logging.getLogger(__name__)
logger.info("This script is deprecated. Use PostgreSQL dump/restore tools instead.")

if __name__ == "__main__":
    print("This script is deprecated. Please use PostgreSQL tools like pg_dump and pg_restore.")
    print("Example:")
    print("  pg_dump -h localhost -U postgres -d flashcards -f backup.sql")
    print("  psql -h localhost -U postgres -d flashcards -f backup.sql")
    exit(1)

