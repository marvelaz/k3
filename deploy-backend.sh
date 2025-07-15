#!/bin/bash

echo "Deploying backend to K3s..."

# Build the image first
./build-backend.sh

# Import image to K3s (for local development)
k3s ctr images import <(docker save expense-tracker-backend:latest)

# Apply manifests
kubectl apply -f backend/backend-configmap.yaml
kubectl apply -f backend/backend-secret.yaml
kubectl apply -f backend/backend-deployment.yaml
kubectl apply -f backend/backend-service.yaml

echo "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n expense-tracker --timeout=300s

echo "Backend deployment complete!"
echo "To test the API:"
echo "kubectl port-forward -n expense-tracker svc/backend-service 8000:8000"
echo "Then visit: http://localhost:8000/docs"