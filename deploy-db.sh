#!/bin/bash

echo "Deploying PostgreSQL database to K3s..."

# Apply all database manifests
kubectl apply -f database/namespace.yaml
kubectl apply -f database/postgres-secret.yaml
kubectl apply -f database/postgres-configmap.yaml
kubectl apply -f database/postgres-pvc.yaml
kubectl apply -f database/postgres-deployment.yaml
kubectl apply -f database/postgres-service.yaml

echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n expense-tracker --timeout=300s

echo "PostgreSQL deployment complete!"
echo "To connect to the database:"
echo "kubectl port-forward -n expense-tracker svc/postgres-service 5432:5432"
echo "Then connect with: psql -h localhost -U postgres -d expense_tracker"