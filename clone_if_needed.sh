#!/bin/bash

# Usage: ./clone_if_needed.sh https://github.com/user/repo.git

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <git-url>"
    exit 1
fi

GIT_URL="$1"
PROJECT_NAME=$(basename -s .git "$GIT_URL")
CODE_DIR="code"

# Create code directory if it doesn't exist
mkdir -p "$CODE_DIR"

# Check if the project directory exists
if [ -d "$CODE_DIR/$PROJECT_NAME" ]; then
    echo "Directory '$CODE_DIR/$PROJECT_NAME' already exists. Skipping clone."
else
    echo "Cloning $GIT_URL into $CODE_DIR/$PROJECT_NAME..."
    git clone "$GIT_URL" "$CODE_DIR/$PROJECT_NAME"
fi
