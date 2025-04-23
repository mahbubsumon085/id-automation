#!/bin/bash

module=$1
dir_to_python_script=$2 
full_test_name=$3
iterations=${4:-5}  # Default to 100 iterations if not provided

MVNOPTIONS="-Ddependency-check.skip=true -Dgpg.skip=true -DfailIfNoTests=false -Dskip.installnodenpm -Dskip.npm -Dskip.yarn -Dlicense.skip -Dcheckstyle.skip -Drat.skip -Denforcer.skip -Danimal.sniffer.skip -Dmaven.javadoc.skip -Dfindbugs.skip -Dwarbucks.skip -Dmodernizer.skip -Dimpsort.skip -Dmdep.analyze.skip -Dpgpverify.skip -Dxml.skip -Dcobertura.skip=true -Dfindbugs.skip=true"

echo "Parameters: module=$module, dir_to_python_script=$dir_to_python_script, full_test_name=$full_test_name, iterations=$iterations"
mvn clean install -DskipTests -pl "$module" -am $MVNOPTIONS || { echo "Error: Maven install failed."; exit 1; }

# Initialize counters
pass_count=0
fail_count=0
error_count=0

# Loop for the specified number of iterations
for ((i=0; i<iterations; i++)); do
    find . -name "TEST-*.xml" -delete
    set -x

    mvn -pl $module test -Dtest=$full_test_name $MVNOPTIONS |& tee mvn-test-$i.log
    
    # Strip ANSI escape codes and process the log
    sed -r "s/\x1B\[[0-9;]*[a-zA-Z]//g" mvn-test-$i.log | \
    egrep "^Running|^\[INFO\] Running " | \
    rev | cut -d' ' -f1 | rev | \
    while read -r g; do
        f=$(find . -name "TEST-${g}.xml" -not -path "*target/surefire-reports/junitreports/*")
        fcount=$(echo "$f" | wc -l)
        if [[ "$fcount" == "1" ]]; then
            python "$dir_to_python_script"/python-scripts/parse_surefire_report.py "$f" "$i" "$full_test_name" >> rounds-test-results.csv
            break
        else
            echo "================ ERROR finding TEST-${g}.xml: $fcount:"
            echo "$f"
        fi
    done
    set +x

    # Create necessary directories
    mkdir -p "flaky-result/testlog"
    mkdir -p "flaky-result/surefire-reports"

    # Move the log file
    mv mvn-test-$i.log "flaky-result/testlog"

    # Move the test result XML files
    for f in $(find . -name "TEST-*.xml" -not -path "*target/surefire-reports/*"); do 
        mv "$f" "flaky-result/testlog"
    done

    # Copy the surefire-reports folder to flaky-result
    cp -r "$module/target/surefire-reports" "flaky-result/surefire-reports/reports-$i"
done

# Count pass, failure, and error from column B in rounds-test-results.csv
while IFS=',' read -r col1 col2 col3; do
    if [[ $col2 == "pass" ]]; then
        ((pass_count++))
    elif [[ $col2 == "failure" ]]; then
        ((fail_count++))
    elif [[ $col2 == "error" ]]; then
        ((error_count++))
    fi
done < rounds-test-results.csv

# Output the counts
echo "Summary:"
echo "Passes: $pass_count"
echo "Failures: $fail_count"
echo "Errors: $error_count"

# Output the counts and log to a summary file
summary_file="flaky-result/summary.txt"
{
    echo "Summary:"
    echo "Passes: $pass_count"
    echo "Failures: $fail_count"
    echo "Errors: $error_count"
} > "$summary_file"

# Move the results CSV to the flaky-result directory
mv rounds-test-results.csv "flaky-result/"

