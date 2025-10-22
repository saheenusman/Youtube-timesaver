# Simple progress tracking system
import time
import threading
from typing import Dict, Any

# Global dictionary to store job progress
jobs = {}

def create_job(youtube_url: str) -> str:
    """Create a new analysis job and return job ID"""
    job_id = f"job_{int(time.time() * 1000)}"
    
    # Initialize job
    jobs[job_id] = {
        'url': youtube_url,
        'teacher_progress': 0.0,
        'analyst_progress': 0.0,
        'explorer_progress': 0.0,
        'status': 'started',
        'result': None,
        'error': None,
        'created_at': time.time()
    }
    
    # Start the work in background
    thread = threading.Thread(target=simulate_work, args=(job_id,))
    thread.daemon = True
    thread.start()
    
    return job_id

def get_job_progress(job_id: str) -> Dict[str, Any]:
    """Get progress for a job"""
    if job_id not in jobs:
        return {'error': 'Job not found'}
    return jobs[job_id]

def simulate_work(job_id: str):
    """Simulate the actual analysis work with progress updates"""
    try:
        job = jobs[job_id]
        job['status'] = 'processing'
        
        # Simulate teacher agent (2 seconds)
        for i in range(20):
            time.sleep(0.1)
            job['teacher_progress'] = min(1.0, (i + 1) / 20)
        
        # Simulate analyst agent (1.5 seconds, overlapping)
        for i in range(15):
            time.sleep(0.1)
            job['analyst_progress'] = min(1.0, (i + 1) / 15)
        
        # Simulate explorer agent (1.8 seconds, overlapping)
        for i in range(18):
            time.sleep(0.1)
            job['explorer_progress'] = min(1.0, (i + 1) / 18)
        
        # Final processing
        time.sleep(0.5)
        
        # Simulate getting results
        from .analysis_core import orchestrate_analysis
        result = orchestrate_analysis(job['url'])
        
        job['result'] = result
        job['status'] = 'completed'
        
    except Exception as e:
        job['error'] = str(e)
        job['status'] = 'failed'

def cleanup_old_jobs():
    """Remove jobs older than 1 hour"""
    current_time = time.time()
    expired_jobs = []
    
    for job_id, job_data in jobs.items():
        if current_time - job_data['created_at'] > 3600:  # 1 hour
            expired_jobs.append(job_id)
    
    for job_id in expired_jobs:
        del jobs[job_id]