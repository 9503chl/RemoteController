# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies required by the project
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    build-essential \
    v4l-utils \
    && rm -rf /var/lib/apt/lists/*

# Copy the Python application source code into the container
COPY ./Deep-Live-Cam-main /app

# The original requirements.txt is platform-specific.
# We will use a dedicated requirements file for the Docker environment.
# First, copy the docker-specific requirements file
COPY ./Deep-Live-Cam-main/requirements.docker.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.docker.txt

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Define environment variable
ENV NAME World

# Run api_server.py when the container launches
CMD ["python", "api_server.py"] 