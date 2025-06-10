#!/bin/bash

# Execute the main script and capture its output
OUTPUT=$(./get_weather.sh)

# Check if the main script executed successfully (exit code 0)
if [ $? -ne 0 ]; then
    echo "Error: get_weather.sh did not execute successfully."
    echo "Output from get_weather.sh:"
    echo "${OUTPUT}"
    exit 1
fi

# Define expected patterns
PATTERNS=(
    "Temperature:"
    "Weather:"
    "Wind Speed:"
    "Wind Direction:"
)

# Flag to track if all patterns are found
ALL_FOUND=true

# Check for each pattern
for pattern in "${PATTERNS[@]}"; do
    if ! echo "${OUTPUT}" | grep -q "${pattern}"; then
        echo "Error: Pattern '${pattern}' not found in the output."
        ALL_FOUND=false
    fi
done

# Final check and exit status
if [ "${ALL_FOUND}" = true ]; then
    echo "All expected patterns found. Test passed."
    exit 0
else
    echo "One or more patterns missing. Test failed."
    echo "Full output from get_weather.sh:"
    echo "${OUTPUT}"
    exit 1
fi
