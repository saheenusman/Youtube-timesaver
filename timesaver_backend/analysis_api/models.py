from django.db import models
from django.utils import timezone

class VideoAnalysis(models.Model):
    """Store completed video analysis results"""
    # Device/User Information
    device_id = models.CharField(max_length=100, db_index=True, default='legacy-device')  # Device authentication
    
    # Video Information
    video_url = models.URLField(max_length=500)
    video_id = models.CharField(max_length=20, db_index=True)  # YouTube ID (removed unique constraint)
    title = models.CharField(max_length=500)
    duration = models.CharField(max_length=20)
    thumbnail_url = models.URLField(max_length=500)
    
    # Analysis Results
    highlights = models.JSONField()  # Store the entire highlights array
    analysis_summary = models.TextField(blank=True)
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    analysis_status = models.CharField(max_length=20, default='completed')
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['device_id']),
            models.Index(fields=['video_id']),
            models.Index(fields=['created_at']),
            models.Index(fields=['device_id', 'video_id']),  # Compound index for device + video
        ]
        # Allow same video to be analyzed by different devices
        unique_together = ['device_id', 'video_id']
    
    def __str__(self):
        return f"{self.title[:50]}... ({self.created_at.strftime('%Y-%m-%d')})"
    
    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            'id': self.id,
            'title': self.title,
            'duration': self.duration,
            'thumbnailUrl': self.thumbnail_url,
            'highlights': self.highlights,
            'created_at': self.created_at.isoformat(),
            'video_url': self.video_url,
        }

class UserSession(models.Model):
    """Track user sessions for analytics and rate limiting"""
    session_id = models.CharField(max_length=100, unique=True)
    first_visit = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    total_analyses = models.IntegerField(default=0)
    device_info = models.JSONField(default=dict, blank=True)
    
    def __str__(self):
        return f"Session {self.session_id[:8]}... ({self.total_analyses} analyses)"

class VideoBookmark(models.Model):
    """Store user bookmarks for favorite videos"""
    session_id = models.CharField(max_length=100)
    video_analysis = models.ForeignKey(VideoAnalysis, on_delete=models.CASCADE)
    bookmarked_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['session_id', 'video_analysis']
        ordering = ['-bookmarked_at']
    
    def __str__(self):
        return f"Bookmark: {self.video_analysis.title[:30]}..."
