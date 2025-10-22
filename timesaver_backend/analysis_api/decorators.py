# analysis_api/decorators.py
from functools import wraps
from django.http import JsonResponse

def add_rate_limit_headers(view_func):
    """
    Decorator to add rate limiting headers to API responses
    """
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        response = view_func(request, *args, **kwargs)
        
        # Add rate limiting headers if available
        if hasattr(request, 'rate_limit_remaining'):
            response['X-RateLimit-Remaining'] = str(request.rate_limit_remaining)
        if hasattr(request, 'rate_limit_reset'):
            response['X-RateLimit-Reset'] = str(request.rate_limit_reset)
        
        return response
    
    return wrapper