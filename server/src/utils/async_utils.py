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
