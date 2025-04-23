chown -R $USER:$USER code/
chmod -R u+rwX data


chmod +x process_id_test.sh
./process_id_test.sh id_accepted_uiuc.csv  
# Git checkout to specific SHA inside Flaky
cd "$FLAKY_DIR" || exit 1

chmod +x process_id_test_jostzip.sh
./process_id_test_jostzip.sh id_accepted_uiuc.csv  



# Get merged SHA from PR link
MERGED_SHA=$(./get_merged_commit.sh "$PR_LINK" | grep -oE '[a-f0-9]{40}')

if [ -n "$MERGED_SHA" ]; then
    echo "Merged Commit SHA from PR: $MERGED_SHA"
    
    cd "$DEST_DIR/Fixed" || exit 1
    git reset --hard
    git clean -fd

    if git rev-parse --git-dir > /dev/null 2>&1; then
        if git checkout "$MERGED_SHA"; then
            echo "Checked out Merged SHA $MERGED_SHA in $FIXED_DIR"
        else
            echo "❌ Error: Failed to checkout merged SHA $MERGED_SHA in $FIXED_DIR"
        fi
    else
        echo "Warning: No .git repo found in Fixed folder, skipping checkout."
    fi
    cd ../../..
else
    echo "No merged commit found for PR: $PR_LINK"
fi
