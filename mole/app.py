import os
import asyncio
import tempfile
import uuid
import threading
import time
import shutil
import hashlib
import subprocess
import json
import sys
import logging
from concurrent.futures import ThreadPoolExecutor
from functools import wraps
from flask import Flask, request, jsonify
from browser_use import Agent
from dotenv import load_dotenv
import requests
from pathlib import Path
from steel import Steel
from browser_use import BrowserSession

load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max request size

# Configuration from environment
PORT = int(os.getenv('PORT', 5001))
HOST = os.getenv('HOST', '0.0.0.0')
DEBUG_MODE = os.getenv('DEBUG', 'false').lower() == 'true'
API_KEY = os.getenv('MOLE_API_KEY')  # For endpoint authentication
GIF_DIR = os.getenv('GIF_DIR', './gifs')

# Authentication decorator
def require_api_key(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not API_KEY:
            # If no API key configured, allow access (for development)
            return f(*args, **kwargs)
        
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'Missing or invalid Authorization header'}), 401
        
        token = auth_header.split(' ')[1]
        if token != API_KEY:
            return jsonify({'error': 'Invalid API key'}), 401
        
        return f(*args, **kwargs)
    return decorated_function

# Worker pool configuration
MAX_WORKERS = 2  # Use limited workers to stay within Steel session limits
executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)
jobs = {}  # Store job status and results

class BrowserAgent:
    def __init__(self):
        """Initialize Steel client"""
        steel_api_key = os.getenv('STEEL_API_KEY')
        if not steel_api_key:
            raise ValueError("STEEL_API_KEY environment variable is required")
        self.steel_client = Steel(steel_api_key=steel_api_key)
    
    def create_agent(self, task_prompt, provider="anthropic", model=None, api_key=None, gif_path=None, initial_actions=None):
        """Create an agent with Steel cloud browser session"""
        if provider == "anthropic":
            from browser_use.llm import ChatAnthropic
            llm = ChatAnthropic(
                model=model or "claude-3-7-sonnet-20250219", 
                api_key=api_key
            )
        elif provider == "openai":
            from browser_use.llm import ChatOpenAI
            llm = ChatOpenAI(
                model=model or "gpt-4o-mini", 
                api_key=api_key
            )
        elif provider == "gemini":
            from browser_use.llm import ChatGoogle
            llm = ChatGoogle(
                model=model or "gemini-2.0-flash-exp"
            )
        else:
            raise ValueError(f"Unsupported provider: {provider}")
        
        # Create Steel cloud browser session
        try:
            steel_session = self.steel_client.sessions.create()
            session_id = steel_session.id
            logger.info(f"Created Steel session {session_id}")
        except Exception as e:
            logger.error(f"Failed to create Steel browser session: {str(e)}")
            raise Exception(f"Failed to create Steel browser session: {str(e)}")
        
        # Create CDP URL for Steel browser connection
        steel_api_key = os.getenv('STEEL_API_KEY')
        cdp_url = f"wss://connect.steel.dev?apiKey={steel_api_key}&sessionId={session_id}"
        
        # Create browser session with Steel CDP URL
        browser_session = BrowserSession(cdp_url=cdp_url)
        
        # Create agent with the actual task prompt
        agent_kwargs = {
            "task": task_prompt,
            "llm": llm,
            "browser_session": browser_session
        }
        
        # Enable GIF generation for debugging
        if gif_path:
            agent_kwargs["generate_gif"] = gif_path
        
        if initial_actions:
            agent_kwargs["initial_actions"] = initial_actions
        
        return Agent(**agent_kwargs), session_id
    
    async def upload_to_hackclub_cdn(self, file_path):
        """Upload file to Hack Club CDN via Bucky transfer"""
        try:
            # Step 1: Upload to Bucky (temporary storage)
            with open(file_path, 'rb') as f:
                files = {'file': f}
                bucky_response = requests.post(
                    'https://bucky.hackclub.com/',
                    files=files,
                    timeout=30
                )
            
            if bucky_response.status_code != 200:
                raise Exception(f"Bucky upload failed: {bucky_response.status_code} - {bucky_response.text}")
            
            bucky_url = bucky_response.text.strip()
            
            # Step 2: Transfer from Bucky to CDN (permanent storage)
            cdn_response = requests.post(
                'https://cdn.hackclub.com/upload',
                json={'url': bucky_url},
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            if cdn_response.status_code == 200:
                # CDN returns the permanent URL
                cdn_data = cdn_response.json()
                return cdn_data.get('url', bucky_url)  # Fallback to bucky URL if no CDN URL
            else:
                # If CDN transfer fails, return the Bucky URL as fallback
                return bucky_url
                
        except Exception as e:
            raise Exception(f"Failed to upload to CDN: {str(e)}")
    
    async def run_task(self, task_prompt, urls=None, provider="anthropic", model=None, api_key=None):
        """Run a generic browser automation task with recording"""
        gif_path = None
        gif_url = None
        steel_session_id = None
        agent = None
        
        try:
            # Create local GIFs directory for debugging
            gifs_dir = os.path.abspath(GIF_DIR)
            os.makedirs(gifs_dir, exist_ok=True)
            
            session_id = str(uuid.uuid4())
            gif_path = os.path.join(gifs_dir, f"session_{session_id}.gif")
            
            # Build the full task prompt with URLs
            if urls:
                urls_text = "\n".join([f"- {url}" for url in urls if url])
                full_prompt = f"{task_prompt}\n\nURLs to visit:\n{urls_text}"
                
                # Start at the first URL to speed things up
                initial_actions = [{'go_to_url': {'url': urls[0], 'new_tab': False}}]
            else:
                full_prompt = task_prompt
                initial_actions = None
            
            # Create agent with the complete task prompt and initial action
            agent, steel_session_id = self.create_agent(full_prompt, provider, model, api_key, gif_path=gif_path, initial_actions=initial_actions)
            
            # Run the task
            start_time = time.time()
            result = await agent.run()
            end_time = time.time()
            duration = end_time - start_time
            
            # Check if GIF was generated and upload to Bucky
            gif_url = None
            if gif_path and os.path.exists(gif_path):
                try:
                    # Upload to Bucky CDN
                    gif_url = await self.upload_to_hackclub_cdn(gif_path)
                except Exception as e:
                    # Fallback to local path if upload fails
                    gif_url = f"file://{gif_path}"
            
            # Wait a bit to ensure browser actions complete
            if duration < 5:  # If task completed very quickly, it might be an error
                await asyncio.sleep(2)  # Give time for potential delayed actions
            
            # Extract result properly
            if hasattr(result, 'final_result'):
                final_result = result.final_result()
            elif hasattr(result, 'result'):
                final_result = result.result
            else:
                final_result = str(result)
            
            return {
                "success": True,
                "result": final_result,
                "raw_result": str(result),  # Include raw result for debugging
                "gif_url": gif_url,
                "gif_path": gif_path if os.path.exists(gif_path) else None,
                "session_id": steel_session_id or session_id,
                "error": None
            }
            
        except Exception as e:
            return {
                "success": False,
                "result": None,
                "gif_url": None,
                "session_id": steel_session_id,
                "error": str(e)
            }
        finally:
            # Clean up Steel session if it was created
            if steel_session_id:
                try:
                    # Close browser session first
                    if agent and hasattr(agent, 'browser_session'):
                        await agent.browser_session.close()
                    
                    # Release Steel session using the correct API method
                    self.steel_client.sessions.release(steel_session_id)
                    
                    logger.info(f"Successfully released Steel session {steel_session_id}")
                except Exception as cleanup_error:
                    logger.warning(f"Failed to cleanup Steel session {steel_session_id}: {cleanup_error}")

def run_task_subprocess(job_id, task_prompt, urls, provider, model, api_key):
    """Launch task in separate subprocess for complete isolation"""
    result_file = None
    try:
        # Update job status
        jobs[job_id]["status"] = "running"
        jobs[job_id]["started_at"] = time.time()
        
        # Create temporary files for communication
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as input_file:
            input_path = input_file.name
            task_data = {
                "task_prompt": task_prompt,
                "urls": urls,
                "provider": provider,
                "model": model,
                "api_key": api_key,
                "job_id": job_id
            }
            json.dump(task_data, input_file)
        
        # Create result file path
        result_file = tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False)
        result_path = result_file.name
        result_file.close()
        
        # Launch subprocess with file-based communication
        process = subprocess.Popen([
            sys.executable, __file__, "--subprocess", input_path, result_path
        ], 
        stdout=subprocess.DEVNULL,  # No stdout needed
        stderr=subprocess.DEVNULL,  # Suppress stderr 
        )
        
        # Wait for subprocess to complete
        return_code = process.wait()
        
        logger.info(f"Job {job_id} completed with return code: {return_code}")
        
        # Read result from file
        if return_code == 0 and os.path.exists(result_path):
            try:
                with open(result_path, 'r') as f:
                    result = json.load(f)
                jobs[job_id]["status"] = "completed"
                jobs[job_id]["result"] = result
                jobs[job_id]["completed_at"] = time.time()
                logger.info(f"Job {job_id} completed successfully")
            except (json.JSONDecodeError, IOError) as e:
                # Handle JSON parsing or file reading error
                jobs[job_id]["status"] = "failed"
                jobs[job_id]["error"] = f"Failed to read subprocess result: {e}"
                jobs[job_id]["completed_at"] = time.time()
                logger.error(f"Job {job_id} result file read error: {e}")
        else:
            # Handle subprocess error
            error_msg = "No result file created"
            if os.path.exists(result_path):
                try:
                    with open(result_path, 'r') as f:
                        error_content = f.read()
                        if error_content:
                            error_msg = f"Subprocess error in result file: {error_content[:200]}"
                except:
                    pass
            
            jobs[job_id]["status"] = "failed"
            jobs[job_id]["error"] = f"Subprocess failed with return code {return_code}. {error_msg}"
            jobs[job_id]["completed_at"] = time.time()
            logger.error(f"Job {job_id} subprocess failed: {error_msg}")
            
    except Exception as e:
        # Update job with error
        jobs[job_id]["status"] = "failed"
        jobs[job_id]["error"] = str(e)
        jobs[job_id]["completed_at"] = time.time()
    finally:
        # Clean up temporary files
        try:
            if 'input_path' in locals() and os.path.exists(input_path):
                os.unlink(input_path)
            if 'result_path' in locals() and os.path.exists(result_path):
                os.unlink(result_path)
        except:
            pass

@app.route('/run', methods=['POST'])
@require_api_key
def start_browser_task():
    """Start a browser automation task"""
    data = request.get_json()
    
    if not data:
        return jsonify({"error": "No JSON data provided"}), 400
    
    task_prompt = data.get('task')
    urls = data.get('urls', [])
    provider = data.get('provider', 'anthropic')
    model = data.get('model')
    api_key = data.get('api_key')
    
    if not task_prompt:
        return jsonify({"error": "Task prompt is required"}), 400
    
    # Use API key from env if not provided in request
    if not api_key:
        if provider == 'anthropic':
            api_key = os.getenv('ANTHROPIC_API_KEY')
        elif provider == 'openai':
            api_key = os.getenv('OPENAI_API_KEY')
        elif provider == 'gemini':
            api_key = os.getenv('GEMINI_API_KEY')
    
    if not api_key:
        return jsonify({"error": f"API key is required for {provider}"}), 400
    
    # Create job
    job_id = str(uuid.uuid4())
    jobs[job_id] = {
        "status": "queued",
        "task": task_prompt,
        "provider": provider,
        "model": model,
        "urls": urls,
        "created_at": time.time(),
        "result": None,
        "error": None
    }
    
    # Submit to thread pool
    executor.submit(run_task_subprocess, job_id, task_prompt, urls, provider, model, api_key)
    
    return jsonify({
        "job_id": job_id,
        "status": "queued",
        "message": f"Task submitted to worker pool ({len([j for j in jobs.values() if j['status'] == 'running'])} running, {len([j for j in jobs.values() if j['status'] == 'queued'])} queued)"
    })

@app.route('/status/<job_id>', methods=['GET'])
@require_api_key
def get_job_status(job_id):
    """Get status of a specific job"""
    if job_id not in jobs:
        return jsonify({"error": "Job not found"}), 404
    
    job = jobs[job_id].copy()
    # Calculate duration if job is running or completed
    if "started_at" in job and job["started_at"]:
        end_time = job.get("completed_at", time.time())
        job["duration"] = round(end_time - job["started_at"], 2)
    
    return jsonify(job)

@app.route('/jobs', methods=['GET'])
@require_api_key
def list_jobs():
    """List all jobs with their status"""
    job_list = []
    for job_id, job_data in jobs.items():
        job_summary = {
            "job_id": job_id,
            "status": job_data["status"],
            "task": job_data["task"][:100] + "..." if len(job_data["task"]) > 100 else job_data["task"],
            "provider": job_data["provider"],
            "created_at": job_data["created_at"]
        }
        if "started_at" in job_data and job_data["started_at"]:
            end_time = job_data.get("completed_at", time.time())
            job_summary["duration"] = round(end_time - job_data["started_at"], 2)
        job_list.append(job_summary)
    
    # Sort by creation time (newest first)
    job_list.sort(key=lambda x: x["created_at"], reverse=True)
    
    return jsonify({
        "jobs": job_list,
        "summary": {
            "total": len(jobs),
            "queued": len([j for j in jobs.values() if j["status"] == "queued"]),
            "running": len([j for j in jobs.values() if j["status"] == "running"]),
            "completed": len([j for j in jobs.values() if j["status"] == "completed"]),
            "failed": len([j for j in jobs.values() if j["status"] == "failed"]),
            "max_workers": MAX_WORKERS
        }
    })

@app.route('/dashboard')
@require_api_key
def dashboard():
    """Web dashboard showing job status"""
    job_list = []
    for job_id, job_data in jobs.items():
        job_info = {
            "job_id": job_id,
            "status": job_data["status"],
            "task": job_data["task"],
            "provider": job_data["provider"],
            "model": job_data.get("model", "default"),
            "created_at": time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(job_data["created_at"])),
            "duration": None,
            "error": job_data.get("error")
        }
        
        if "started_at" in job_data and job_data["started_at"]:
            end_time = job_data.get("completed_at", time.time())
            job_info["duration"] = round(end_time - job_data["started_at"], 2)
        
        if job_data["status"] == "completed" and job_data.get("result"):
            job_info["success"] = job_data["result"].get("success", False)
            if job_data["result"].get("result"):
                job_info["result_preview"] = str(job_data["result"]["result"])[:200]
            if job_data["result"].get("gif_url"):
                job_info["gif_url"] = job_data["result"]["gif_url"]
        
        job_list.append(job_info)
    
    # Sort by creation time (newest first)
    job_list.sort(key=lambda x: x["job_id"], reverse=True)
    
    summary = {
        "total": len(jobs),
        "queued": len([j for j in jobs.values() if j["status"] == "queued"]),
        "running": len([j for j in jobs.values() if j["status"] == "running"]),
        "completed": len([j for j in jobs.values() if j["status"] == "completed"]),
        "failed": len([j for j in jobs.values() if j["status"] == "failed"]),
        "max_workers": MAX_WORKERS
    }
    
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Mole Browser Dashboard</title>
        <meta http-equiv="refresh" content="5">
        <style>
            body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
            .header {{ background-color: #333; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }}
            .summary {{ background-color: white; padding: 15px; border-radius: 5px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
            .jobs {{ background-color: white; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
            .job {{ padding: 15px; border-bottom: 1px solid #eee; }}
            .job:last-child {{ border-bottom: none; }}
            .status {{ padding: 4px 8px; border-radius: 3px; color: white; font-size: 12px; font-weight: bold; }}
            .status.queued {{ background-color: #ffa500; }}
            .status.running {{ background-color: #007bff; }}
            .status.completed {{ background-color: #28a745; }}
            .status.failed {{ background-color: #dc3545; }}
            .task {{ font-weight: bold; margin: 5px 0; }}
            .details {{ color: #666; font-size: 14px; }}
            .job-id {{ font-family: monospace; font-size: 12px; color: #999; }}
            .error {{ background-color: #f8d7da; color: #721c24; padding: 8px; border-radius: 3px; margin-top: 5px; }}
            .result-preview {{ background-color: #d4edda; color: #155724; padding: 8px; border-radius: 3px; margin-top: 5px; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class="header">
            <h1>🐭 Mole Browser Dashboard</h1>
            <p>Auto-refreshes every 5 seconds</p>
        </div>
        
        <div class="summary">
            <h2>Worker Summary</h2>
            <p><strong>Workers:</strong> {summary['running']}/{summary['max_workers']} running, {summary['queued']} queued</p>
            <p><strong>Jobs:</strong> {summary['total']} total ({summary['completed']} completed, {summary['failed']} failed)</p>
        </div>
        
        <div class="jobs">
            <h2>Recent Jobs</h2>
    """
    
    if not job_list:
        html += "<div class='job'>No jobs yet</div>"
    else:
        for job in job_list:
            duration_text = f" ({job['duration']}s)" if job['duration'] else ""
            html += f"""
            <div class="job">
                <div class="task">{job['task'][:100]}{'...' if len(job['task']) > 100 else ''}</div>
                <div class="details">
                    <span class="status {job['status']}">{job['status'].upper()}</span>
                    {job['provider']} ({job['model']}) • {job['created_at']}{duration_text}
                </div>
                <div class="job-id">{job['job_id']}</div>
            """
            
            if job.get('error'):
                html += f"<div class='error'>Error: {job['error']}</div>"
            
            if job.get('result_preview'):
                html += f"<div class='result-preview'>Result: {job['result_preview']}...</div>"
            
            if job.get('gif_url'):
                if job['gif_url'].startswith('http'):
                    # Bucky CDN URL
                    html += f"<div class='result-preview'>🎬 GIF: <a href='{job['gif_url']}' target='_blank'>View GIF</a></div>"
                else:
                    # Local file fallback
                    gif_filename = os.path.basename(job['gif_url'].replace('file://', ''))
                    html += f"<div class='result-preview'>🎬 GIF: <a href='{job['gif_url']}' target='_blank'>{gif_filename}</a></div>"
            
            html += "</div>"
    
    html += """
        </div>
    </body>
    </html>
    """
    
    return html

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    steel_sessions = None
    steel_error = None
    
    try:
        # Create a temporary Steel client to check session status
        steel_api_key = os.getenv('STEEL_API_KEY')
        if steel_api_key:
            steel_client = Steel(steel_api_key=steel_api_key)
            steel_sessions = steel_client.sessions.list()
    except Exception as e:
        steel_error = str(e)
    
    health_data = {
        "status": "healthy", 
        "service": "mole-browser",
        "workers": {
            "max": MAX_WORKERS,
            "running": len([j for j in jobs.values() if j["status"] == "running"]),
            "queued": len([j for j in jobs.values() if j["status"] == "queued"])
        }
    }
    
    if steel_sessions is not None:
        # Convert cursor to list to get count and session IDs
        sessions_list = list(steel_sessions.data if hasattr(steel_sessions, 'data') else steel_sessions)
        health_data["steel_sessions"] = {
            "active_count": len(sessions_list)
        }
    elif steel_error:
        health_data["steel_sessions"] = {"error": steel_error}
    
    return jsonify(health_data)

@app.route('/cleanup-sessions', methods=['POST'])
@require_api_key
def cleanup_steel_sessions():
    """Manually clean up all Steel sessions"""
    try:
        steel_api_key = os.getenv('STEEL_API_KEY')
        if not steel_api_key:
            return jsonify({"error": "Steel API key not configured"}), 500
        
        steel_client = Steel(steel_api_key=steel_api_key)
        
        # List current sessions
        sessions = steel_client.sessions.list()
        sessions_list = list(sessions.data if hasattr(sessions, 'data') else sessions)
        session_ids = [s.id for s in sessions_list]
        
        if not session_ids:
            return jsonify({"message": "No active sessions to clean up", "cleaned": 0})
        
        # Release all sessions
        steel_client.sessions.release_all()
        
        return jsonify({
            "message": f"Successfully cleaned up {len(session_ids)} sessions",
            "cleaned": len(session_ids),
            "session_ids": session_ids
        })
        
    except Exception as e:
        return jsonify({"error": f"Failed to cleanup sessions: {str(e)}"}), 500

def subprocess_worker():
    """Worker function that runs in subprocess for complete browser isolation"""
    if len(sys.argv) < 4:
        sys.exit(1)
    
    input_path = sys.argv[2]
    result_path = sys.argv[3]
    
    try:
        # Suppress ALL logging to prevent any output interference
        import logging
        logging.disable(logging.CRITICAL)
        
        # Redirect stderr to null
        sys.stderr = open(os.devnull, 'w')
        
        # Read task data from input file
        with open(input_path, 'r') as f:
            task_data = json.load(f)
        
        # Extract task parameters
        task_prompt = task_data["task_prompt"]
        urls = task_data.get("urls", [])
        provider = task_data["provider"]
        model = task_data.get("model")
        api_key = task_data["api_key"]
        job_id = task_data["job_id"]
        
        # Create browser agent and run task
        browser_agent = BrowserAgent()
        
        # Run async task
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            result = loop.run_until_complete(
                browser_agent.run_task(task_prompt, urls, provider, model, api_key)
            )
            
            # Write result to output file
            with open(result_path, 'w') as f:
                json.dump(result, f)
            
        finally:
            loop.close()
            
    except Exception as e:
        # Write error result to output file
        error_result = {
            "success": False,
            "result": None,
            "error": str(e)
        }
        try:
            with open(result_path, 'w') as f:
                json.dump(error_result, f)
        except:
            pass  # If we can't write the error, at least exit cleanly
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == "--subprocess":
        subprocess_worker()
    else:
        app.run(host=HOST, port=PORT, debug=DEBUG_MODE)
