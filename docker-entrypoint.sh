#!/bin/bash
set -e

# Function to handle shutdown signals
cleanup() {
    echo "Received shutdown signal, stopping services..."
    kill -TERM "$api_pid" "$ingestion_pid" 2>/dev/null
    wait "$api_pid" "$ingestion_pid"
    exit 0
}

# Set up signal trap
trap cleanup SIGTERM SIGINT

# Start API service in background
python backend/api.py &
api_pid=$!

# Wait a bit for API to start
sleep 5

# Start ingestion service in background
python backend/ingestion_service.py &
ingestion_pid=$!

# Wait for both processes
wait "$api_pid" "$ingestion_pid"
