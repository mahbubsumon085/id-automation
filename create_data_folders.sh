#!/bin/bash

# Usage: ./create_data_folders.sh <folder-name>

# Check if folder name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <folder-name>"
    exit 1
fi

BASE_NAME="$1"
BASE_DIR="data/$BASE_NAME"

# Create base directory
mkdir -p "$BASE_DIR"

# Create the four subdirectories
for sub in Fixed Flaky Flakym2 Fixedm2; do
    mkdir -p "$BASE_DIR/$sub"
done

echo "Folders created inside $BASE_DIR: Fixed, Flaky, Flakym2, Fixedm2"

