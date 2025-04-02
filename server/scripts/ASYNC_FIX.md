# Flask Async Route Fix

## Problem

Your Flask application was encountering an error with async routes:

```
TypeError: The view function did not return a valid response. The return type must be a string, dict, list, tuple with headers or status, Response instance, or WSGI callable, but it was a coroutine.
```

This happens because Flask doesn't natively support async/await syntax in route functions. When you declare a route with `async def`, Flask doesn't know how to handle the coroutine that's returned.

## Solution

1. Created a new utility file `src/utils/async_utils.py` with an `async_route` decorator:
   ```python
   import asyncio
   from functools import wraps

   def async_route(f):
       """
       Decorator to make async route functions work with Flask.
       Wrap your async route functions with this decorator.
       """
       @wraps(f)
       def wrapped(*args, **kwargs):
           return asyncio.run(f(*args, **kwargs))
       return wrapped
   ```

2. Updated the route functions in `src/routes/grading_routes.py` to use this decorator:
   ```python
   @grading_bp.route('/grade', methods=['POST'])
   @auth_required
   @async_route  # Add this decorator
   async def grade_answer():
       # Function body remains the same
   ```

## How It Works

The `async_route` decorator converts your async route function into a synchronous function that Flask can handle. When the route is called, it uses `asyncio.run()` to execute your async function and returns the result back to Flask.

## Why Your Frontend Was Getting 500 Errors

The Flutter app was making POST requests to `/api/grade`, but Flask was returning 500 errors because it couldn't handle the async route function. Now with the fix, the route properly returns a valid JSON response.

## Testing

After restarting your Flask server, the API call from your Flutter app should work correctly.
