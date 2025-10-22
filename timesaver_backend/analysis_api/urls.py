# analysis_api/urls.py
from django.urls import path
from . import views

urlpatterns = [
    # Original analysis endpoint
    path('analyze/', views.analyze_video, name='analyze_video'),
    
    # Async analysis endpoints
    path('start/', views.start_analysis_view, name='start_analysis'),
    path('progress/<str:job_id>/', views.get_progress, name='get_progress'),
    
    # New database-powered endpoints
    path('history/', views.get_analysis_history, name='get_history'),
    path('search/', views.search_analyses, name='search_analyses'),
    path('analysis/<int:analysis_id>/', views.delete_analysis, name='delete_analysis'),
    path('stats/', views.get_stats, name='get_stats'),
    
    # Bookmark endpoints
    path('bookmark/', views.toggle_bookmark, name='toggle_bookmark'),
    path('bookmarks/', views.get_bookmarks, name='get_bookmarks'),
    path('bookmark/<int:bookmark_id>/', views.remove_bookmark, name='remove_bookmark'),
    path('bookmark/status/<int:analysis_id>/', views.check_bookmark_status, name='check_bookmark_status'),
    
    # Development/testing endpoints
    path('test/', views.mobile_connection_test, name='mobile_test'),
    path('debug/', views.debug_test, name='debug_test'),
]