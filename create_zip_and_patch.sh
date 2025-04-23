#!/bin/bash

# Usage: ./create_zip_and_patch.sh <flaky_commit_sha> <fixed_commit_sha> <cloned_source_dir> <folder_name>
# Example: ./create_zip_and_patch.sh abc123 def456 code/projectX projectX-TestFoo

FLAKY_COMMIT="$1"
FIXED_COMMIT="$2"
SOURCE_DIR="$3"      # Absolute or relative path to cloned source (e.g., code/projectX)
FOLDER_NAME="$4"     # Just the folder name inside data/, not full path (e.g., projectX-TestFoo)

if [ -z "$FLAKY_COMMIT" ] || [ -z "$FIXED_COMMIT" ] || [ -z "$SOURCE_DIR" ] || [ -z "$FOLDER_NAME" ]; then
    echo "Usage: $0 <flaky_commit_sha> <fixed_commit_sha> <cloned_source_dir> <folder_name>"
    exit 1
fi

FLAKY_DIR="data/$FOLDER_NAME/Flaky"
FIXED_DIR="data/$FOLDER_NAME/Fixed"
WORKING_DIR="data/$FOLDER_NAME"

echo "🧹 Deleting old Flaky and Fixed directories..."
rm -rf "$FLAKY_DIR"
rm -rf "$FIXED_DIR"

echo "📁 Copying source to Flaky..."
cp -r "$SOURCE_DIR" "$FLAKY_DIR"
(
    cd "$FLAKY_DIR" || exit 1
    git checkout "$FLAKY_COMMIT"
    rm -rf .git
)

echo "📁 Copying source to Fixed..."
cp -r "$SOURCE_DIR" "$FIXED_DIR"
(
    cd "$FIXED_DIR" || exit 1
    git checkout "$FIXED_COMMIT"
    rm -rf .git
)

echo "🧵 Creating Fixed.patch..."
(
    cd "$WORKING_DIR" || { echo "❌ Could not enter $WORKING_DIR"; exit 1; }

    if [ ! -d Flaky ] || [ ! -d Fixed ]; then
        echo "❌ Flaky or Fixed directory does not exist."
        ls -al
        exit 1
    fi

    echo "📂 Contents before diff:"
    echo "🔸 Flaky:"
    ls -R Flaky
    echo "🔹 Fixed:"
    ls -R Fixed

    echo "🔧 Running diff..."
    diff -ruN Flaky Fixed > Fixed.patch

    if [ $? -eq 0 ]; then
        echo "ℹ️ No differences found — Fixed.patch will be empty."
    else
        echo "✅ Diff completed — Fixed.patch created."
    fi

    echo "🧹 Deleting Fixed directory..."
    rm -rf Fixed
)

echo "🗜️ Creating zip and cleaning up..."
(
    cd data || exit 1
    zip -r "${FOLDER_NAME}.zip" "$FOLDER_NAME"
    rm -rf "$FOLDER_NAME"
)

echo "✅ Done! Created zip at: data/${FOLDER_NAME}.zip"
