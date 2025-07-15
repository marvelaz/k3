#!/bin/bash

echo "Deploying frontend to K3s..."

# Build the image first
./build-frontend.sh

# Import image to K3s (for local development)
echo "Importing image to K3s..."
k3s ctr images import <(docker save expense-tracker-frontend:latest)

# Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f frontend/frontend-configmap.yaml
kubectl apply -f frontend/frontend-deployment.yaml
kubectl apply -f frontend/frontend-service.yaml
kubectl apply -f frontend/frontend-ingress.yaml

# Wait for deployment to be ready
echo "Waiting for frontend to be ready..."
kubectl wait --for=condition=ready pod -l app=frontend -n expense-tracker --timeout=300s

echo "Frontend deployment complete!"
echo ""
echo "Access methods:"
echo "1. Port forward: kubectl port-forward -n expense-tracker svc/frontend-service 3000:80"
echo "2. Ingress (if configured): http://expense-tracker.local"
echo "3. NodePort (if you change service type): http://<node-ip>:<nodeport>"