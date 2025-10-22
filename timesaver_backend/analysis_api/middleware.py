# analysis_api/middleware.py
from django.http import JsonResponse
from django.utils.deprecation import MiddlewareMixin
from .rate_limiting import RateLimiter
import logging

logger = logging.getLogger(__name__)

class DeviceAuthenticationMiddleware(MiddlewareMixin):
    """
    Middleware to require device ID for API endpoints
    """
    
    # Endpoints that require device authentication
    PROTECTED_PATHS = [
        '/api/analyze/',
        '/api/history/',
        '/api/search/',
        '/api/stats/',
        '/api/analysis/',
        '/api/bookmark/',
        '/api/bookmarks/',
    ]
    
    # Endpoints that don't require authentication (for testing/debugging)
    EXEMPT_PATHS = [
        '/api/test/',
        '/api/debug/',
        '/admin/',
    ]
    
    def process_request(self, request):
        # Skip authentication for exempt paths
        if any(request.path.startswith(path) for path in self.EXEMPT_PATHS):
            return None
            
        # Check if path requires device authentication
        if any(request.path.startswith(path) for path in self.PROTECTED_PATHS):
            device_id = request.headers.get('X-Device-ID')
            
            if not device_id:
                logger.warning(f"Missing device ID for {request.path} from {request.META.get('REMOTE_ADDR')}")
                return JsonResponse({
                    'error': 'Device ID required',
                    'detail': 'Include X-Device-ID header with a valid device identifier'
                }, status=401)
            
            if len(device_id) < 10:  # Basic validation (UUIDs are longer)
                logger.warning(f"Invalid device ID format: {device_id[:8]}...")
                return JsonResponse({
                    'error': 'Invalid device ID format',
                    'detail': 'Device ID must be a valid identifier'
                }, status=401)
            
            # Add device_id to request for views to use
            request.device_id = device_id
            
            # Check rate limiting for this device and endpoint
            allowed, remaining, reset_time = RateLimiter.check_rate_limit(device_id, request.path)
            
            if not allowed:
                return RateLimiter.get_rate_limit_response(remaining, reset_time)
            
            # Add rate limit info to request for response headers
            request.rate_limit_remaining = remaining
            request.rate_limit_reset = reset_time
            
            logger.info(f"Authenticated device {device_id[:8]}... for {request.path}")
        
        return None