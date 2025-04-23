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
        flaky_result=$(./run_test_on_flaky_directory.sh "data/$folder_name/Flaky" "$module_path" "$fq_test_modified" 5 | tee /dev/stderr | tail -n 1)

        # Ensure flaky_result is numeric before comparison
        if [[ "$flaky_result" =~ ^[0-9]+$ ]] && [ "$flaky_result" -gt 0 ]; then
            echo "📊 flaky_result = $flaky_result. Running post_process.sh..."
            fixed_result=$(./run_test_on_fixed_directory.sh "data/$folder_name/Fixed" "$module_path" "$fq_test_modified" 5 | tee /dev/stderr | tail -n 1)

                if [[ "$fixed_result" =~ ^[0-9]+$ ]] && [ "$flaky_result" -gt 0 ]; then
                    echo "need to create the zip file"
                    ./create_zip_and_patch.sh "$sha" "$RESULT" "code/$cloned_directory_name" "$folder_name"

                    CONFIG_FILE="test_config.csv"
                        new_row="id,$folder_name,$folder_name,$module_path,,${fq_test_modified},10,All"

                        # Check if row with same test_type and issue_id already exists
                        if grep -q "^id,$folder_name," "$CONFIG_FILE"; then
                            echo "⚠️  Row for test_type=id and issue_id=$folder_name already exists in $CONFIG_FILE — skipping append."
                        else
                            echo "$new_row" >> "$CONFIG_FILE"
                            echo "✅ Appended to $CONFIG_FILE: $new_row"
                        fi

                    
                else
                    echo "failed for fixed"
                fi


        else
            echo "ℹ️ flaky_result = $flaky_result. Skipping post_process.sh"
        fi


    else
        echo "⚠️  No valid merged commit SHA found. Skipping test execution for row $row_num."
    fi

    echo "---------------------------------------------"


done