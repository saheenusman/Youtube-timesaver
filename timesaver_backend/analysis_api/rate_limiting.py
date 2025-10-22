# analysis_api/rate_limiting.py
from django.core.cache import cache
from django.http import JsonResponse
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)

class RateLimiter:
    """
    Rate limiting system for API abuse prevention
    """
    
    # Rate limiting configuration
    RATE_LIMITS = {
        'analyze': {
            'max_requests': 5,      # Maximum requests
            'window_seconds': 60,   # Time window in seconds
            'endpoint': '/api/analyze/',
        },
        'search': {
            'max_requests': 30,     # More generous for search
            'window_seconds': 60,
            'endpoint': '/api/search/',
        },
        'history': {
            'max_requests': 20,     # Moderate for history
            'window_seconds': 60,
            'endpoint': '/api/history/',
        }
    }
    
    @staticmethod
    def check_rate_limit(device_id, endpoint_path):
        """
        Check if device has exceeded rate limit for the endpoint
        Returns: (allowed: bool, remaining: int, reset_time: int)
        """
        
        # Determine which rate limit to apply
        rate_config = None
        for limit_type, config in RateLimiter.RATE_LIMITS.items():
            if endpoint_path.startswith(config['endpoint']):
                rate_config = config
                break
        
        if not rate_config:
            # No rate limit configured for this endpoint
            return True, 999, 0
        
        # Create cache key for this device + endpoint
        cache_key = f"rate_limit:{device_id[:16]}:{limit_type}"
        window_seconds = rate_config['window_seconds']
        max_requests = rate_config['max_requests']
        
        # Get current timestamp
        now = int(timezone.now().timestamp())
        
        # Get existing requests in current window
        request_times = cache.get(cache_key, [])
        
        # Remove requests outside the current window
        cutoff_time = now - window_seconds
        request_times = [t for t in request_times if t > cutoff_time]
        
        # Check if limit exceeded
        if len(request_times) >= max_requests:
            # Rate limit exceeded
            oldest_request = min(request_times) if request_times else now
            reset_time = oldest_request + window_seconds
            remaining = 0
            
            logger.warning(
                f"Rate limit exceeded for device {device_id[:8]}... "
                f"on {limit_type}: {len(request_times)}/{max_requests} requests"
            )
            
            return False, remaining, reset_time
        
        # Add current request to the list
        request_times.append(now)
        
        # Store updated request times (expire after window + 10 seconds buffer)
        cache.set(cache_key, request_times, window_seconds + 10)
        
        remaining = max_requests - len(request_times)
        reset_time = now + window_seconds
        
        logger.info(
            f"Rate limit check passed for device {device_id[:8]}... "
            f"on {limit_type}: {len(request_times)}/{max_requests} requests, "
            f"{remaining} remaining"
        )
        
        return True, remaining, reset_time
    
    @staticmethod
    def get_rate_limit_response(remaining, reset_time):
        """
        Generate standardized rate limit exceeded response
        """
        reset_in = max(0, reset_time - int(timezone.now().timestamp()))
        
        return JsonResponse({
            'error': 'Rate limit exceeded',
            'detail': f'Too many requests. Try again in {reset_in} seconds.',
            'retry_after': reset_in,
            'remaining_requests': remaining,
            'reset_time': reset_time
        }, status=429)  # HTTP 429 Too Many Requests