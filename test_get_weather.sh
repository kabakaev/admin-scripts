#!/bin/bash

TOWN_TO_TEST="Oslo" # Using a reliable town for testing

# Execute the main script with a town name and capture its output
echo "Running get_weather.sh with town: ${TOWN_TO_TEST}"
OUTPUT=$(./get_weather.sh "${TOWN_TO_TEST}")
SCRIPT_EXIT_CODE=$?

# Check if the main script executed successfully (exit code 0)
if [ ${SCRIPT_EXIT_CODE} -ne 0 ]; then
    echo "Error: get_weather.sh did not execute successfully. Exit code: ${SCRIPT_EXIT_CODE}"
    echo "Output from get_weather.sh:"
    echo "${OUTPUT}"
    exit 1
fi

# Define expected patterns
# Adding town name specific checks as well
PATTERNS=(
    "Fetching coordinates for ${TOWN_TO_TEST}..."
    "Coordinates found: Lat="
    "Fetching weather data for ${TOWN_TO_TEST} (Lat: "
    "Current Weather in ${TOWN_TO_TEST}:"
    "Temperature:"
    "Weather:"
    "Wind Speed:"
    "Wind Direction:"
)

# Flag to track if all patterns are found
ALL_FOUND=true

echo "--- Checking output for expected patterns ---"
echo "${OUTPUT}" # Print the output for easier debugging if a pattern is not found
echo "-------------------------------------------"

# Check for each pattern
for pattern in "${PATTERNS[@]}"; do
    if ! echo "${OUTPUT}" | grep -qF "${pattern}"; then # Use -F for fixed string matching, -q for quiet
        echo "Error: Pattern '${pattern}' not found in the output."
        ALL_FOUND=false
    fi
done

# Final check and exit status
if [ "${ALL_FOUND}" = true ]; then
    echo "All expected patterns found for ${TOWN_TO_TEST}. Test passed."
    exit 0
else
    echo "One or more patterns missing for ${TOWN_TO_TEST}. Test failed."
    # Full output was already printed if script failed initially or can be printed here again if needed
    # echo "Full output from get_weather.sh:"
    # echo "${OUTPUT}"
    exit 1
fi
