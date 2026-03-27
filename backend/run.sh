#!/bin/bash

# Create a virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Check for .env file
if [ ! -f ".env" ]; then
    echo "WARNING: .env file not found. Copying .env.example..."
    cp .env.example .env
    echo "Please edit the .env file with your FIREBASE_SERVICE_ACCOUNT_PATH."
fi

# Run the FastAPI server
echo "Starting FastAPI server on http://localhost:8000..."
python main.py
