#!/bin/bash

# Usage: ./run_statistics_generator.sh <flaky_dir> <module_path> <fq_test> <iterations>

FLAKY_DIR="$1"
MODULE="$2"
FQ_TEST="$3"
ITERATIONS="$4"

if [ -z "$FLAKY_DIR" ] || [ -z "$MODULE" ] || [ -z "$FQ_TEST" ] || [ -z "$ITERATIONS" ]; then
    echo "Usage: $0 <flaky_dir> <module_path> <fq_test> <iterations>"
    exit 1
fi

ROOT_DIR=$(pwd)

cp id_jdk8_statistics_generator.sh "$FLAKY_DIR"
chmod +x "$FLAKY_DIR/id_jdk8_statistics_generator.sh"

cd "$FLAKY_DIR" || exit 1

TOTAL_ROUNDS=$(./id_jdk8_statistics_generator.sh "$MODULE" "$FQ_TEST" "$ITERATIONS" | tee /dev/stderr | grep "Total Rounds:" | awk '{print $3}')

echo "Captured TOTAL_ROUNDS: $TOTAL_ROUNDS"


if [ -d "$HOME/.m2" ]; then
    echo "✅ ~/.m2 exists. Attempting to move it to one level up from $FLAKY_DIR"

    cd .. || exit 1  # go one level up from Flaky

    # Create target dir if it doesn't already exist (just in case)
    mkdir -p Flakym2

    # Move .m2 with sudo
     mv "$HOME/.m2" Flakym2

    if [ $? -eq 0 ]; then
        echo "✅ Successfully moved ~/.m2 to $(pwd)/Flakym2"
    else
        echo "❌ mv failed! Check permissions or lock issues"
        exit 1
    fi
else
    echo "⚠️ ~/.m2 does not exist — skipping move"
fi


cd "$ROOT_DIR" || exit 1

echo "$TOTAL_ROUNDS"