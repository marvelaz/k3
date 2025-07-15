#!/bin/bash

echo "Building backend Docker image..."

# Build the Docker image
docker build -t expense-tracker-backend:latest ./backend/

# If using a registry, tag and push
# docker tag expense-tracker-backend:latest your-registry/expense-tracker-backend:latest
# docker push your-registry/expense-tracker-backend:latest

echo "Backend image built successfully!"