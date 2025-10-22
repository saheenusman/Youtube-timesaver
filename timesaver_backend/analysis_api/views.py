# analysis_api/views.py
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
import json
import logging
import time
from django.db.models import Q
from django.utils import timezone

# Import the updated core logic
from .analysis_core import orchestrate_analysis, extract_youtube_id
from .simple_progress import create_job, get_job_progress, cleanup_old_jobs
from .models import VideoAnalysis, UserSession, VideoBookmark
from .decorators import add_rate_limit_headers

logger = logging.getLogger(__name__)

@api_view(['POST'])
@add_rate_limit_headers
def analyze_video(request):
    """
    Receives a YouTube URL and initiates the AI agent analysis using Gemini.
    Now includes database caching to avoid re-analyzing same videos.
    """
    
    # 1. Input Validation
    try:
        data = json.loads(request.body)
        youtube_url = data.get('url')
    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON format in request body."}, status=status.HTTP_400_BAD_REQUEST)

    if not youtube_url:
        return Response({"error": "Missing 'url' parameter."}, status=status.HTTP_400_BAD_REQUEST)
    
    # 2. Extract video ID and check device-specific cache
    try:
        video_id = extract_youtube_id(youtube_url)
        device_id = request.device_id  # From middleware
        
        # Check if this device already analyzed this video
        try:
            existing_analysis = VideoAnalysis.objects.get(
                video_id=video_id, 
                device_id=device_id
            )
            logger.info(f"Returning cached analysis for device {device_id[:8]}... video: {video_id}")
            
            # Add agent status for UI compatibility
            result_data = existing_analysis.to_dict()
            result_data['agents'] = [
                {"name": "The Teacher", "status": "Completed", "progress": 1.0},
                {"name": "The Analyst", "status": "Completed", "progress": 1.0},
                {"name": "The Explorer", "status": "Completed", "progress": 1.0},
            ]
            
            return Response(result_data, status=status.HTTP_200_OK)
            
        except VideoAnalysis.DoesNotExist:
            # Video not analyzed by this device before, proceed with new analysis
            logger.info(f"Starting new analysis for device {device_id[:8]}... video: {video_id}")
            pass
            
    except Exception as e:
        logger.error(f"Error extracting video ID from {youtube_url}: {str(e)}")
        return Response({"error": "Invalid YouTube URL format."}, status=status.HTTP_400_BAD_REQUEST)
    
    # 3. Run New Analysis
    try:
        logger.info(f"Starting Gemini analysis for URL: {youtube_url}")
        
        result_data = orchestrate_analysis(youtube_url)
        
        # 4. Save analysis to database with device association
        try:
            analysis = VideoAnalysis.objects.create(
                device_id=device_id,
                video_url=youtube_url,
                video_id=video_id,
                title=result_data['title'],
                duration=result_data['duration'],
                thumbnail_url=result_data['thumbnailUrl'],
                highlights=result_data['highlights'],
                analysis_status='completed'
            )
            logger.info(f"Saved analysis to database for device {device_id[:8]}... ID: {analysis.id}")
            
            # Add the database ID to the response data for bookmark functionality
            result_data['id'] = analysis.id
            
        except Exception as db_error:
            logger.error(f"Failed to save analysis to database: {str(db_error)}")
            # Continue anyway - return results even if DB save fails
        
        # Add agent status for the Flutter UI's AgentCard progress display
        result_data['agents'] = [
            {"name": "The Teacher", "status": "Simplifying", "progress": 1.0},
            {"name": "The Analyst", "status": "Analyzing", "progress": 1.0},
            {"name": "The Explorer", "status": "Exploring", "progress": 1.0},
        ]
        
        return Response(result_data, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Full analysis failed for {youtube_url}: {str(e)}")
        # Check if the error is due to a missing API key or an invalid request
        error_message = "Failed to complete AI analysis. Ensure GEMINI_API_KEY is set and the URL is valid."
        if "API_KEY" in str(e) or "Authentication" in str(e):
             error_message = "Authentication Error: Gemini API key is missing or invalid."

        return Response(
            {"error": error_message, "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
def start_analysis_view(request):
    """
    Start async analysis and return job ID for progress tracking.
    """
    try:
        data = json.loads(request.body)
        youtube_url = data.get('url')
    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON format in request body."}, status=status.HTTP_400_BAD_REQUEST)

    if not youtube_url:
        return Response({"error": "Missing 'url' parameter."}, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        # Clean up old jobs first
        cleanup_old_jobs()
        
        # Start the analysis
        job_id = create_job(youtube_url)
        
        logger.info(f"Started async analysis with job ID: {job_id}")
        
        return Response({
            "job_id": job_id,
            "status": "started",
            "message": "Analysis started successfully"
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Failed to start analysis for {youtube_url}: {str(e)}")
        return Response(
            {"error": "Failed to start analysis", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_progress(request, job_id):
    """
    Get current progress for a specific job.
    """
    try:
        progress_data = get_job_progress(job_id)
        
        if 'error' in progress_data:
            return Response(progress_data, status=status.HTTP_404_NOT_FOUND)
        
        return Response(progress_data, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Failed to get progress for job {job_id}: {str(e)}")
        return Response(
            {"error": "Failed to get progress", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def mobile_connection_test(request):
    """Simple test endpoint for mobile connectivity"""
    client_ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', 'Unknown'))
    return Response({
        "message": "Mobile connection successful!", 
        "client_ip": client_ip,
        "server_time": time.time(),
        "success": True
    })

@api_view(['GET'])
def debug_test(request):
    """Debug endpoint to test URL routing"""
    client_ip = request.META.get('HTTP_X_FORWARDED_FOR', request.META.get('REMOTE_ADDR', 'Unknown'))
    return Response({
        "message": "Debug endpoint working!", 
        "timestamp": time.time(),
        "client_ip": client_ip,
        "server_ip": "192.168.43.81",
        "headers": dict(request.headers)
    })

# ===== NEW DATABASE-POWERED ENDPOINTS =====

@api_view(['GET'])
@add_rate_limit_headers
def get_analysis_history(request):
    """Get analysis history for the authenticated device"""
    try:
        device_id = request.device_id  # From middleware
        
        # Get query parameters
        limit = int(request.GET.get('limit', 20))
        offset = int(request.GET.get('offset', 0))
        
        # Get analyses for this device only
        analyses = VideoAnalysis.objects.filter(device_id=device_id)[offset:offset + limit]
        total_count = VideoAnalysis.objects.filter(device_id=device_id).count()
        
        # Convert to list for JSON response
        analyses_data = [analysis.to_dict() for analysis in analyses]
        
        logger.info(f"Returned {len(analyses_data)} analyses for device {device_id[:8]}...")
        
        return Response({
            'analyses': analyses_data,
            'total_count': total_count,
            'has_more': offset + limit < total_count,
            'device_id': device_id[:8] + '...'  # For debugging
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Failed to get analysis history: {str(e)}")
        return Response(
            {"error": "Failed to retrieve analysis history", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@add_rate_limit_headers
def search_analyses(request):
    """Search through analysis history for the authenticated device"""
    try:
        device_id = request.device_id  # From middleware
        query = request.GET.get('q', '').strip()
        if not query:
            return Response({"error": "Search query is required"}, status=status.HTTP_400_BAD_REQUEST)
        
        # Search in title and highlights content for this device only
        analyses = VideoAnalysis.objects.filter(
            device_id=device_id
        ).filter(
            Q(title__icontains=query) |
            Q(highlights__icontains=query)
        ).order_by('-created_at')[:50]  # Limit to 50 results
        
        # Convert to list for JSON response
        results = [analysis.to_dict() for analysis in analyses]
        
        logger.info(f"Search '{query}' returned {len(results)} results for device {device_id[:8]}...")
        
        return Response({
            'results': results,
            'total_count': len(results),
            'search_query': query,
            'device_id': device_id[:8] + '...'  # For debugging
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Search failed for query '{request.GET.get('q', '')}': {str(e)}")
        return Response(
            {"error": "Search failed", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['DELETE'])
def delete_analysis(request, analysis_id):
    """Delete a specific analysis (only if owned by authenticated device)"""
    try:
        device_id = request.device_id  # From middleware
        
        # Only allow deletion of analyses owned by this device
        analysis = VideoAnalysis.objects.get(id=analysis_id, device_id=device_id)
        analysis.delete()
        
        logger.info(f"Deleted analysis {analysis_id} for device {device_id[:8]}...")
        return Response({"message": "Analysis deleted successfully"}, status=status.HTTP_200_OK)
        
    except VideoAnalysis.DoesNotExist:
        return Response({
            "error": "Analysis not found or not owned by this device"
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Failed to delete analysis {analysis_id}: {str(e)}")
        return Response(
            {"error": "Failed to delete analysis", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
def get_stats(request):
    """Get comprehensive analytics for the authenticated device"""
    try:
        device_id = request.device_id  # From middleware
        
        # Get stats for this device only
        total_analyses = VideoAnalysis.objects.filter(device_id=device_id).count()
        recent_analyses = VideoAnalysis.objects.filter(
            device_id=device_id,
            created_at__gte=timezone.now() - timezone.timedelta(days=7)
        ).count()
        
        # Calculate total highlights across all analyses for this device
        total_highlights = 0
        device_analyses = VideoAnalysis.objects.filter(device_id=device_id)
        for analysis in device_analyses:
            if isinstance(analysis.highlights, list):
                total_highlights += len(analysis.highlights)
        
        logger.info(f"Stats for device {device_id[:8]}...: {total_analyses} analyses, {total_highlights} highlights")
        
        return Response({
            'total_analyses': total_analyses,
            'recent_analyses': recent_analyses,
            'total_highlights': total_highlights,
            'this_week': recent_analyses,
            'database_status': 'healthy',
            'device_id': device_id[:8] + '...'  # For debugging
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Failed to get stats: {str(e)}")
        return Response(
            {"error": "Failed to retrieve statistics", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@add_rate_limit_headers
def toggle_bookmark(request):
    """Add or remove a bookmark for a video analysis"""
    try:
        data = json.loads(request.body)
        analysis_id = data.get('analysis_id')
        
        if not analysis_id:
            return Response({"error": "Missing 'analysis_id' parameter."}, status=status.HTTP_400_BAD_REQUEST)
        
        device_id = request.device_id  # From middleware
        
        # Check if the analysis exists and belongs to this device
        try:
            video_analysis = VideoAnalysis.objects.get(id=analysis_id, device_id=device_id)
        except VideoAnalysis.DoesNotExist:
            return Response({
                "error": "Analysis not found or not owned by this device"
            }, status=status.HTTP_404_NOT_FOUND)
        
        # Check if bookmark already exists
        bookmark, created = VideoBookmark.objects.get_or_create(
            session_id=device_id,  # Using device_id as session_id for consistency
            video_analysis=video_analysis
        )
        
        if created:
            # Bookmark was created
            logger.info(f"Created bookmark for device {device_id[:8]}... analysis: {analysis_id}")
            return Response({
                "message": "Bookmark added successfully",
                "bookmarked": True,
                "bookmark_id": bookmark.id
            }, status=status.HTTP_201_CREATED)
        else:
            # Bookmark already exists, remove it (toggle behavior)
            bookmark.delete()
            logger.info(f"Removed bookmark for device {device_id[:8]}... analysis: {analysis_id}")
            return Response({
                "message": "Bookmark removed successfully",
                "bookmarked": False
            }, status=status.HTTP_200_OK)
            
    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON format in request body."}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        logger.error(f"Failed to toggle bookmark: {str(e)}")
        return Response(
            {"error": "Failed to toggle bookmark", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@add_rate_limit_headers
def get_bookmarks(request):
    """Get all bookmarks for the authenticated device with optional search"""
    try:
        device_id = request.device_id  # From middleware
        query = request.GET.get('query', '').strip()
        limit = int(request.GET.get('limit', 50))
        offset = int(request.GET.get('offset', 0))
        
        # Get bookmarks for this device
        bookmarks = VideoBookmark.objects.filter(session_id=device_id).select_related('video_analysis')
        
        # Apply search filter if query provided
        if query:
            bookmarks = bookmarks.filter(
                Q(video_analysis__title__icontains=query) |
                Q(video_analysis__highlights__icontains=query)
            )
        
        # Order by most recently bookmarked
        bookmarks = bookmarks.order_by('-bookmarked_at')
        
        # Apply pagination
        total_count = bookmarks.count()
        bookmarks = bookmarks[offset:offset + limit]
        
        # Convert to response format
        bookmarks_data = []
        for bookmark in bookmarks:
            analysis_data = bookmark.video_analysis.to_dict()
            analysis_data['bookmark_id'] = bookmark.id
            analysis_data['bookmarked_at'] = bookmark.bookmarked_at.isoformat()
            bookmarks_data.append(analysis_data)
        
        logger.info(f"Retrieved {len(bookmarks_data)} bookmarks for device {device_id[:8]}... (query: '{query}')")
        
        return Response({
            'bookmarks': bookmarks_data,
            'total_count': total_count,
            'has_more': (offset + limit) < total_count
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Failed to get bookmarks: {str(e)}")
        return Response(
            {"error": "Failed to retrieve bookmarks", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['DELETE'])
@add_rate_limit_headers
def remove_bookmark(request, bookmark_id):
    """Remove a specific bookmark"""
    try:
        device_id = request.device_id  # From middleware
        
        # Find and delete the bookmark (ensure it belongs to this device)
        bookmark = VideoBookmark.objects.get(
            id=bookmark_id,
            session_id=device_id
        )
        
        bookmark.delete()
        logger.info(f"Removed bookmark {bookmark_id} for device {device_id[:8]}...")
        
        return Response({"message": "Bookmark removed successfully"}, status=status.HTTP_200_OK)
        
    except VideoBookmark.DoesNotExist:
        return Response({
            "error": "Bookmark not found or not owned by this device"
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Failed to remove bookmark {bookmark_id}: {str(e)}")
        return Response(
            {"error": "Failed to remove bookmark", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@add_rate_limit_headers
def check_bookmark_status(request, analysis_id):
    """Check if an analysis is bookmarked by the current device"""
    try:
        device_id = request.device_id  # From middleware
        
        # Check if bookmark exists
        bookmark_exists = VideoBookmark.objects.filter(
            session_id=device_id,
            video_analysis_id=analysis_id
        ).exists()
        
        if bookmark_exists:
            bookmark = VideoBookmark.objects.get(
                session_id=device_id,
                video_analysis_id=analysis_id
            )
            return Response({
                "bookmarked": True,
                "bookmark_id": bookmark.id
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                "bookmarked": False
            }, status=status.HTTP_200_OK)
            
    except Exception as e:
        logger.error(f"Failed to check bookmark status: {str(e)}")
        return Response(
            {"error": "Failed to check bookmark status", "details": str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )