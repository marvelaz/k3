#!/bin/bash

echo "Testing database connection..."

# Port forward to access the database
kubectl port-forward -n expense-tracker svc/postgres-service 5432:5432 &
PF_PID=$!

# Wait a moment for port forward to establish
sleep 3

# Test connection (you'll need psql installed)
PGPASSWORD=postgres_password psql -h localhost -U postgres -d expense_tracker -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"

# Kill port forward
kill $PF_PID

echo "Database test complete!"