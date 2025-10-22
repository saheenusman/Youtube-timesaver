# analysis_api/analysis_core_progress.py

import os
import asyncio
import json
import time
from datetime import datetime
from typing import Dict, Any
from .analysis_core import orchestrate_analysis

# In-memory storage for progress tracking (in production, use Redis/database)
analysis_progress = {}

class AnalysisProgressTracker:
    def __init__(self, job_id: str):
        self.job_id = job_id
        self.start_time = time.time()
        
    def update_progress(self, agent: str, progress: float, status: str = ""):
        """Update progress for a specific agent (0.0 to 1.0)"""
        if self.job_id not in analysis_progress:
            analysis_progress[self.job_id] = {
                'teacher_progress': 0.0,
                'analyst_progress': 0.0,
                'explorer_progress': 0.0,
                'teacher_status': 'Initializing...',
                'analyst_status': 'Waiting...',
                'explorer_status': 'Waiting...',
                'overall_status': 'started',
                'result': None,
                'error': None,
                'start_time': self.start_time,
            }
        
        agent_key = f"{agent.lower()}_progress"
        status_key = f"{agent.lower()}_status"
        
        analysis_progress[self.job_id][agent_key] = progress
        if status:
            analysis_progress[self.job_id][status_key] = status
            
        print(f"[{self.job_id}] {agent} progress: {progress:.2f} - {status}")

def get_progress_status(progress: float) -> str:
    """Convert progress float to status text"""
    if progress == 0.0:
        return 'Initializing...'
    elif progress < 0.3:
        return 'Starting analysis...'
    elif progress < 0.6:
        return 'Processing data...'
    elif progress < 0.9:
        return 'Finalizing results...'
    elif progress >= 1.0:
        return 'Complete!'
    else:
        return 'Working...'

async def simulate_agent_work(tracker: AnalysisProgressTracker, agent: str, duration: float, start_delay: float = 0):
    """Simulate realistic agent work with progress updates"""
    
    # Wait for start delay
    if start_delay > 0:
        await asyncio.sleep(start_delay)
    
    # Start the agent
    tracker.update_progress(agent, 0.0, "Starting analysis...")
    
    # Simulate work in steps
    steps = 20
    step_duration = duration / steps
    
    for i in range(steps + 1):
        progress = min(i / steps, 1.0)
        status = get_progress_status(progress)
        tracker.update_progress(agent, progress, status)
        
        if i < steps:  # Don't sleep after the last step
            await asyncio.sleep(step_duration)

async def run_analysis_with_progress(job_id: str, youtube_url: str):
    """Run the full analysis with realistic progress tracking"""
    try:
        # Check if job exists (should be initialized by start_analysis)
        if job_id not in analysis_progress:
            print(f"[{job_id}] Error: Job not found in progress tracker")
            return
            
        tracker = AnalysisProgressTracker(job_id)
        
        # Update overall status
        analysis_progress[job_id]['overall_status'] = 'processing'
        
        # Start all agents with realistic timing
        teacher_task = simulate_agent_work(tracker, 'teacher', 2.0, 0.0)      # Starts immediately, 2s
        analyst_task = simulate_agent_work(tracker, 'analyst', 2.5, 0.5)     # Starts after 0.5s, 2.5s  
        explorer_task = simulate_agent_work(tracker, 'explorer', 2.2, 1.0)   # Starts after 1s, 2.2s
        
        # Run agents concurrently
        await asyncio.gather(teacher_task, analyst_task, explorer_task)
        
        # Once all agents complete, run the actual backend analysis
        print(f"[{job_id}] All agents complete, running actual analysis...")
        result = orchestrate_analysis(youtube_url)
        
        # Store the result
        analysis_progress[job_id]['result'] = result
        analysis_progress[job_id]['overall_status'] = 'completed'
        
        print(f"[{job_id}] Analysis completed successfully")
        
    except Exception as e:
        print(f"[{job_id}] Analysis failed: {str(e)}")
        if job_id in analysis_progress:
            analysis_progress[job_id]['error'] = str(e)
            analysis_progress[job_id]['overall_status'] = 'failed'
        else:
            print(f"[{job_id}] Could not update progress - job not found")

def start_analysis(youtube_url: str) -> str:
    """Start async analysis and return job ID"""
    job_id = f"job_{int(time.time() * 1000)}"  # Simple job ID
    
    print(f"[DEBUG] Creating job: {job_id}")
    
    # Initialize job data FIRST to prevent race condition
    analysis_progress[job_id] = {
        'teacher_progress': 0.0,
        'analyst_progress': 0.0,
        'explorer_progress': 0.0,
        'overall_status': 'starting',
        'result': None,
        'error': None,
        'start_time': time.time()
    }
    
    print(f"[DEBUG] Job {job_id} initialized. Current jobs: {list(analysis_progress.keys())}")
    
    # Start the async analysis in background thread
    import threading
    thread = threading.Thread(
        target=lambda: asyncio.run(run_analysis_with_progress(job_id, youtube_url))
    )
    thread.daemon = True
    thread.start()
    
    print(f"[DEBUG] Thread started for job: {job_id}")
    return job_id

def get_analysis_progress(job_id: str) -> Dict[str, Any]:
    """Get current progress for a job"""
    print(f"[DEBUG] Looking for job: {job_id}")
    print(f"[DEBUG] Available jobs: {list(analysis_progress.keys())}")
    
    if job_id not in analysis_progress:
        print(f"[DEBUG] Job {job_id} not found in progress tracker")
        return {'error': f'Job {job_id} not found'}
    
    progress_data = analysis_progress[job_id]
    print(f"[DEBUG] Returning progress for {job_id}: {progress_data}")
    return progress_data

def cleanup_old_jobs():
    """Clean up jobs older than 1 hour"""
    current_time = time.time()
    expired_jobs = []
    
    for job_id, data in analysis_progress.items():
        if current_time - data.get('start_time', 0) > 3600:  # 1 hour
            expired_jobs.append(job_id)
    
    for job_id in expired_jobs:
        del analysis_progress[job_id]
        print(f"Cleaned up expired job: {job_id}")