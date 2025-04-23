#!/bin/bash

# Usage: ./copy_to_flaky_fixed.sh <cloned_repo_dir> <destination_data_dir> <sha> <pr_link> <row_line>

CLONED_DIR="$1"
DEST_DIR="$2"
SHA="$3"
PR_LINK="$4"
ROW_LINE="$5"

if [ -z "$CLONED_DIR" ] || [ -z "$DEST_DIR" ] || [ -z "$SHA" ] || [ -z "$PR_LINK" ]; then
    echo "Usage: $0 <cloned_repo_dir> <destination_data_dir> <sha> <pr_link> [row_line]"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CSV_FILE="$SCRIPT_DIR/id_accepted_uiuc.csv"

# Verify the cloned directory exists
if [ ! -d "$CLONED_DIR" ]; then
    echo "Error: Cloned directory '$CLONED_DIR' does not exist."
    exit 1
fi

# Verify the destination directories exist
if [ ! -d "$DEST_DIR/Flaky" ] || [ ! -d "$DEST_DIR/Fixed" ]; then
    echo "Error: Either Flaky or Fixed folder doesn't exist in '$DEST_DIR'."
    exit 1
fi

# Copy all content including hidden files and .git folder
cp -a "$CLONED_DIR"/. "$DEST_DIR/Flaky/"
cp -a "$CLONED_DIR"/. "$DEST_DIR/Fixed/"

echo "Copied contents of $CLONED_DIR to:"
echo "  → $DEST_DIR/Flaky/"
echo "  → $DEST_DIR/Fixed/"

# Perform git checkout inside Flaky folder
cd "$DEST_DIR/Flaky" || exit 1

git reset --hard
git clean -fd

if git rev-parse --git-dir > /dev/null 2>&1; then
    git checkout "$SHA"
    echo "Checked out SHA $SHA in $DEST_DIR/Flaky"
else
    echo "Warning: No .git repo found in Flaky folder, skipping checkout."
fi

cd "$SCRIPT_DIR"

# Get merged SHA from PR link
MERGED_SHA=$(./get_merged_commit.sh "$PR_LINK" | grep -oE '[a-f0-9]{40}')
RESULT="not-found"

if [ -n "$MERGED_SHA" ]; then
    echo "Merged Commit SHA from PR: $MERGED_SHA"
    cd "$DEST_DIR/Fixed" || exit 1
    git reset --hard
    git clean -fd

    if git rev-parse --git-dir > /dev/null 2>&1; then
        if git checkout "$MERGED_SHA"; then
            echo "✅ Checked out Merged SHA $MERGED_SHA in $DEST_DIR/Fixed"
            RESULT="$MERGED_SHA"
        else
            echo "Direct checkout failed. Trying to fetch merge ref from GitHub..."
            if [[ "$PR_LINK" =~ github.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
                PR_NUMBER="${BASH_REMATCH[3]}"
                git fetch origin "pull/$PR_NUMBER/merge"
                if git checkout FETCH_HEAD; then
                    echo "✅ Checked out FETCH_HEAD (GitHub merge ref for PR #$PR_NUMBER) in $DEST_DIR/Fixed"
                    RESULT="$MERGED_SHA"
                else
                    echo "❌ Error: Failed to checkout merged SHA or FETCH_HEAD."
                fi
            else
                echo "❌ Error: Invalid PR URL."
            fi
        fi
    else
        echo "Warning: No .git repo found in Fixed folder, skipping checkout."
    fi
else
    echo "❌ No merged commit found for PR: $PR_LINK"
fi

cd "$SCRIPT_DIR"

# Update CSV if row number is provided
if [ -n "$ROW_LINE" ] && [ "$ROW_LINE" -gt 1 ]; then
    if [ ! -f "$CSV_FILE" ]; then
        echo "❌ CSV file not found: $CSV_FILE"
        exit 1
    fi

    if [ ! -w "$CSV_FILE" ]; then
        echo "❌ CSV file is not writable: $CSV_FILE"
        exit 1
    fi

    TMP_FILE="${CSV_FILE}.tmp"

    awk -F, -v row="$ROW_LINE" -v result="$RESULT" '
    BEGIN { OFS=FS }
    {
        if (NR == row) {
            # Pad to at least 10 columns
            for (i = NF + 1; i <= 10; i++) $i = ""
            $10 = result
            updated = 1
        }
        print
    }
    END {
        if (!updated) {
            print "⚠️  Could not update row " row > "/dev/stderr"
            exit 1
        }
    }
    ' "$CSV_FILE" > "$TMP_FILE"

    if [ $? -eq 0 ]; then
        if mv "$TMP_FILE" "$CSV_FILE"; then
            echo "✅ Successfully updated row $ROW_LINE, column J with '$RESULT'"
        else
            echo "❌ Failed to overwrite CSV file"
            rm -f "$TMP_FILE"
        fi
    else
        echo "❌ Failed to update row $ROW_LINE (row not found or empty)"
        rm -f "$TMP_FILE"
    fi
else
    echo "❌ Invalid or missing row number: '$ROW_LINE'"
fi

echo "Finished processing"
echo "RESULT: $RESULT"