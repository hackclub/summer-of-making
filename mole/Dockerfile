FROM python:3.11-slim

# Install basic tools for health checks
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements first (for caching)
COPY requirements.txt .

# Install Python dependencies (cached unless requirements change)
RUN pip install --no-cache-dir -r requirements.txt

# Set environment variables
ENV PYTHONPATH=/app

# Copy application code LAST (so changes don't invalidate cache)
COPY app.py .

EXPOSE 5001

# Production command (override in docker-compose for dev)
CMD ["gunicorn", "--bind", "0.0.0.0:5001", "--workers", "1", "--worker-class", "sync", "--timeout", "300", "app:app"]
