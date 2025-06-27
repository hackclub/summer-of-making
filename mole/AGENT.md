# AGENT.md - Mole Browser Automation Service

## Overview

Mole is a browser automation service built with Flask and browser-use library. It provides an API to run browser automation tasks using LLM agents with visual feedback via VNC.

## Commands (via Docker Compose)

- **Start Service**: `docker compose up` (starts Flask API on port 5001)
- **Build**: `docker compose build` (rebuild container after changes)
- **VNC Access**: 
  - VNC: `localhost:5901` (requires VNC client)
  - Web VNC: `http://localhost:6080` (browser-based VNC)

## API Endpoints

- **POST /run**: Execute browser automation task
  - Required: `task` (string), `api_key` (string)
  - Optional: `urls` (array), `provider` ("anthropic"|"openai"), `model` (string)
- **GET /health**: Health check endpoint

## Development Notes

- Uses virtual display (:1) for headless browser operations
- Supports both Anthropic Claude and OpenAI GPT models
- GIF recording temporarily disabled (see TODO in app.py)
- Browser runs in non-headless mode for VNC visibility
- Files uploaded to Hack Club Bucky CDN service

## Environment Variables

- `BROWSER_USE_DISABLE_TELEMETRY=true`: Disable telemetry
- `DISPLAY=:1`: Virtual display for browser

## File Structure

- `app.py`: Main Flask application with BrowserAgent class
- `docker-compose.yml`: Service configuration with VNC support
- `Dockerfile`: Container build configuration
- `requirements.txt`: Python dependencies
