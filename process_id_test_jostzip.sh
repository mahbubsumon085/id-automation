#!/bin/bash

# Usage: ./process_csv.sh path/to/id_accepted_uiuc.csv

INPUT_FILE="$1"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 <csv-file>"
    exit 1
fi

# === Ensure helper scripts are executable ===
chmod +x clone_if_needed.sh
chmod +x create_data_folders.sh
chmod +x copy_to_flaky_fixed.sh
chmod +x get_merged_commit.sh
chmod +x run_test_on_flaky_directory.sh
chmod +x run_test_on_fixed_directory.sh
chmod +x create_zip_and_patch.sh



# === Process CSV ===
row_num=1  # CSV header is line 1
tail -n +2 "$INPUT_FILE" | while IFS=',' read -r project_url sha module_path fq_test category status pr_link notes _; do
    row_num=$((row_num + 1))  # Track actual CSV row

    # Remove surrounding quotes
    project_url=$(echo "$project_url" | sed 's/^"\(.*\)"$/\1/')
    sha=$(echo "$sha" | sed 's/^"\(.*\)"$/\1/')
    module_path=$(echo "$module_path" | sed 's/^"\(.*\)"$/\1/')
    fq_test=$(echo "$fq_test" | sed 's/^"\(.*\)"$/\1/')
    category=$(echo "$category" | sed 's/^"\(.*\)"$/\1/')
    status=$(echo "$status" | sed 's/^"\(.*\)"$/\1/')
    pr_link=$(echo "$pr_link" | sed 's/^"\(.*\)"$/\1/')
    notes=$(echo "$notes" | sed 's/^"\(.*\)"$/\1/')

    test_name="${fq_test##*.}"
    fq_test_modified="${fq_test%.*}#${fq_test##*.}"

    echo "  Row               : $row_num"
    echo "  Test              : $fq_test_modified"
    echo "  Test Name Only    : $test_name"

    # === Step 1: Clone repo if needed ===
    ./clone_if_needed.sh "$project_url"

    # === Step 2: Create data folder ===
    cloned_directory_name=$(basename "$project_url" .git)
    folder_name="${cloned_directory_name}-${test_name}"
    ./create_data_folders.sh "$folder_name"

    # === Step 3: Copy repo contents to Flaky and Fixed ===
    RESULT=$(./copy_to_flaky_fixed.sh "code/$cloned_directory_name" "data/$folder_name" "$sha" "$pr_link" "$row_num" | grep "RESULT:" | awk '{print $2}')

    if [ -n "$RESULT" ] && [ "$RESULT" != "not-found" ]; then
        echo "✅ Valid merged commit found: $RESULT. Running tests..."

        # Ensure flaky_result is numeric before comparison
         ./create_zip_and_patch.sh "$sha" "$RESULT" "code/$cloned_directory_name" "$folder_name"


    else
        echo "⚠️  No valid merged commit SHA found. Skipping test execution for row $row_num."
    fi

    echo "---------------------------------------------"


done