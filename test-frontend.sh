#!/bin/bash

echo "Testing frontend deployment..."

# Check if frontend pods are running
echo "Checking frontend pod status..."
kubectl get pods -n expense-tracker -l app=frontend

# Port forward to test
echo "Starting port forward to test frontend..."
kubectl port-forward -n expense-tracker svc/frontend-service 3000:80 &
PF_PID=$!

# Wait for port forward
sleep 3

# Test health endpoint
echo "Testing health endpoint..."
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Frontend health check passed"
else
    echo "❌ Frontend health check failed"
fi

# Test main page
echo "Testing main page..."
if curl -f http://localhost:3000/ > /dev/null 2>&1; then
    echo "✅ Frontend main page accessible"
    echo "🎉 Frontend is working! Open http://localhost:3000 in your browser"
else
    echo "❌ Frontend main page not accessible"
fi

# Clean up
kill $PF_PID 2>/dev/null

echo "Frontend test complete!"