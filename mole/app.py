import os
import asyncio
import tempfile
import uuid
from flask import Flask, request, jsonify
from browser_use import Agent, BrowserSession
from dotenv import load_dotenv
import requests
from pathlib import Path

load_dotenv()

app = Flask(__name__)

class BrowserAgent:
    def create_agent(self, task_prompt, provider="anthropic", model=None, api_key=None, gif_path=None, initial_actions=None):
        """Create an agent with specified provider and credentials"""
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
        else:
            raise ValueError(f"Unsupported provider: {provider}")
        
        # Create browser session with custom configuration
        browser_session = BrowserSession(
            headless=False,  # Make Chrome visible in VNC
            executable_path="/usr/bin/chromium",  # Use system Chromium
            args=[
                "--no-sandbox",
                "--disable-dev-shm-usage", 
                "--disable-gpu",
                "--disable-web-security",
                "--allow-running-insecure-content",
                "--display=:1"   # Use virtual display
            ]
        )
        
        # Create agent with the actual task prompt
        agent_kwargs = {
            "task": task_prompt,
            "llm": llm,
            "browser_session": browser_session
        }
        
        # Note: GIF generation disabled for now due to API issues
        # if gif_path:
        #     agent_kwargs["generate_gif"] = gif_path
        
        if initial_actions:
            agent_kwargs["initial_actions"] = initial_actions
        
        return Agent(**agent_kwargs)
    
    async def upload_to_hackclub_cdn(self, file_path):
        """Upload file to Hack Club Bucky service"""
        try:
            with open(file_path, 'rb') as f:
                files = {'file': f}
                response = requests.post(
                    'https://bucky.hackclub.com/',
                    files=files,
                    timeout=30
                )
            
            if response.status_code == 200:
                # Bucky returns the URL as plain text
                return response.text.strip()
            else:
                raise Exception(f"Bucky upload failed: {response.status_code} - {response.text}")
        except Exception as e:
            raise Exception(f"Failed to upload to Bucky: {str(e)}")
    
    async def run_task(self, task_prompt, urls=None, provider="anthropic", model=None, api_key=None):
        """Run a generic browser automation task with recording"""
        gif_path = None
        gif_url = None
        
        try:
            # Create temporary directory for GIF (even though we're not using it yet)
            temp_dir = tempfile.mkdtemp(prefix="mole_gif_")
            session_id = str(uuid.uuid4())
            gif_path = os.path.join(temp_dir, f"session_{session_id}.gif")
            
            # Build the full task prompt with URLs
            if urls:
                urls_text = "\n".join([f"- {url}" for url in urls if url])
                full_prompt = f"{task_prompt}\n\nURLs to visit:\n{urls_text}"
                
                # Start at the first URL to speed things up
                initial_actions = [{'go_to_url': {'url': urls[0]}}]
            else:
                full_prompt = task_prompt
                initial_actions = None
            
            # Create agent with the complete task prompt and initial action
            agent = self.create_agent(full_prompt, provider, model, api_key, gif_path=gif_path, initial_actions=initial_actions)
            
            # Run the task
            result = await agent.run()
            
            # For now, skip GIF upload since generation isn't working
            # TODO: Fix GIF generation later
            
            return {
                "success": True,
                "result": str(result.final_result()) if hasattr(result, 'final_result') else str(result),
                "gif_url": None,  # Disabled for now
                "session_id": session_id,
                "error": None
            }
            
        except Exception as e:
            return {
                "success": False,
                "result": None,
                "gif_url": None,
                "session_id": None,
                "error": str(e)
            }
        finally:
            # Clean up temporary files
            if gif_path and os.path.exists(gif_path):
                try:
                    os.remove(gif_path)
                    # Remove temp directory if empty
                    temp_dir = os.path.dirname(gif_path)
                    if os.path.exists(temp_dir) and not os.listdir(temp_dir):
                        os.rmdir(temp_dir)
                except:
                    pass

browser_agent = BrowserAgent()

@app.route('/run', methods=['POST'])
def run_browser_task():
    """Execute a generic browser automation task"""
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
    
    if not api_key:
        return jsonify({"error": "API key is required"}), 400
    
    # Run async task
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    
    try:
        result = loop.run_until_complete(
            browser_agent.run_task(task_prompt, urls, provider, model, api_key)
        )
        return jsonify(result)
    except Exception as e:
        return jsonify({
            "success": False,
            "result": None,
            "gif_url": None,
            "session_id": None,
            "error": f"Task execution failed: {str(e)}"
        }), 500
    finally:
        loop.close()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "mole-browser"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
