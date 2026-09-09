# Use the official Python runtime as the base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PORT=8888
ENV HOST=0.0.0.0
ENV ENVIRONMENT=production

# Install system dependencies
#RUN apt-get update && apt-get install -y \
#    curl \
#    && rm -rf /var/lib/apt/lists/*

# Copy requirements.txt and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY app.py .

# Create a non-root user to run the application (security best practice)
RUN useradd -m -r appuser && chown -R appuser /app
USER appuser

# Expose the port
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8888/health || exit 1

# Run the application
CMD ["python", "app.py"]
