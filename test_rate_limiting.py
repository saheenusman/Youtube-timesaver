#!/usr/bin/env python3
"""
Test script to verify rate limiting implementation
"""
import requests
import time
import json

BASE_URL = "http://127.0.0.1:8000/api"
DEVICE_ID = "test-device-12345678901234567890"  # Test device ID

def test_rate_limiting():
    """Test the rate limiting for analyze endpoint"""
    print("🧪 Testing Rate Limiting (5 requests per 60 seconds)")
    print("=" * 50)
    
    headers = {
        'Content-Type': 'application/json',
        'X-Device-ID': DEVICE_ID
    }
    
    payload = {
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'  # Rick Roll for testing
    }
    
    for i in range(7):  # Try 7 requests (should fail after 5)
        try:
            print(f"\n📡 Request {i+1}...")
            response = requests.post(
                f"{BASE_URL}/analyze/",
                headers=headers,
                json=payload,
                timeout=10
            )
            
            print(f"Status: {response.status_code}")
            
            # Check rate limit headers
            remaining = response.headers.get('X-RateLimit-Remaining')
            reset_time = response.headers.get('X-RateLimit-Reset')
            
            if remaining:
                print(f"🚦 Remaining requests: {remaining}")
            if reset_time:
                print(f"⏰ Reset time: {reset_time}")
            
            if response.status_code == 429:
                # Rate limited
                error_data = response.json()
                retry_after = error_data.get('retry_after', 'unknown')
                print(f"🚫 RATE LIMITED! Retry after: {retry_after} seconds")
                print(f"Error: {error_data.get('error')}")
                break
            elif response.status_code == 200:
                print("✅ Success - Analysis completed")
            else:
                print(f"❌ Error: {response.status_code}")
                print(response.text[:200])
                
        except requests.exceptions.RequestException as e:
            print(f"💥 Network error: {e}")
            break
        
        # Small delay between requests
        time.sleep(1)
    
    print("\n" + "=" * 50)
    print("🏁 Rate limiting test completed!")

if __name__ == "__main__":
    test_rate_limiting()