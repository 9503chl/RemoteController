# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Set the working directory in the container
WORKDIR /app

# Install build dependencies required for compiling some python packages and system libraries for OpenCV
RUN apt-get update && apt-get install -y build-essential python3-dev libgl1-mesa-glx libglib2.0-0

# Copy the requirements file into the container at /app
# We use the docker-specific requirements file
COPY requirements.docker.txt .

# Install any needed packages specified in requirements.txt
# We use --no-cache-dir to reduce image size
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.docker.txt

# Copy the rest of the application's code into the container
COPY . .

# Make port 8000 available to the world outside this container
EXPOSE 8000

# Define environment variable
ENV FLASK_APP api_server.py

# Run api_server.py when the container launches
# Use gunicorn for a production-ready server
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "1", "--timeout", "120", "api_server:app"] 