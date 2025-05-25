# Default Data API Tests

## Running the Tests

**IMPORTANT: Run from the server directory, not the test directory**

1. Install test dependencies:
```bash
cd server
pip install -r test/requirements.txt
```

2. Run the comprehensive test:
```bash
# Make sure you're in the server directory
cd server
python test/test_default_data_api.py
```

3. Or run with pytest:
```bash
cd server
pytest test/test_default_data_api.py -v
```

## What the Tests Validate

The test suite validates all 6 new default data API endpoints:
- Health check endpoint
- Categories endpoint  
- Flashcard sets endpoint
- Interview questions endpoint
- Category counts endpoint
- Combined default data endpoint

It checks for correct HTTP status codes, proper JSON structure, data integrity, and consistency across endpoints.
