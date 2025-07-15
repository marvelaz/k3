#!/bin/bash

echo "Building frontend Docker image..."

# Navigate to frontend directory
cd frontend

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Build the Docker image
docker build -t expense-tracker-frontend:latest .

# Tag for registry if needed
# docker tag expense-tracker-frontend:latest your-registry/expense-tracker-frontend:latest

echo "Frontend image built successfully!"

# Go back to root directory
cd ..