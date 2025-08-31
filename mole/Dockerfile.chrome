FROM python:3.11-slim

# Install VNC dependencies, Chromium, and health check tools
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    xvfb \
    x11vnc \
    fluxbox \
    git \
    curl \
    wget \
    && git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first (for caching)
COPY requirements.txt .

# Install Python dependencies (cached unless requirements change)
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN playwright install chromium

# Create VNC startup script with noVNC
RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
Xvfb :1 -screen 0 1920x1080x16 &\n\
sleep 2\n\
fluxbox &\n\
x11vnc -display :1 -nopw -forever -rfbport 5901 &\n\
sleep 2\n\
cd /opt/noVNC && ./utils/novnc_proxy --vnc localhost:5901 --listen 6080 &\n\
sleep 2\n\
python /app/app.py\n\
' > /start.sh && chmod +x /start.sh

# Set environment variables
ENV PYTHONPATH=/app
ENV DISPLAY=:1
ENV CHROME_BIN=/usr/bin/chromium
ENV BROWSER_USE_DISABLE_TELEMETRY=true
ENV BROWSER_USE_SYNC_ENABLED=false

# Copy application code LAST (so changes don't invalidate cache)
COPY app.py .

EXPOSE 5001 5901 6080

# Production command (override in docker-compose for dev)
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "1", "--worker-class", "sync", "--timeout", "300", "app:app"]
