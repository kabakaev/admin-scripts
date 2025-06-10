#!/bin/bash

# Laichingen coordinates
LAT="48.48972"
LON="9.68611"

# API URL
API_URL="https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${LAT}&lon=${LON}"

# User-Agent header
USER_AGENT="MyWeatherApp/1.0 github.com/your-username/your-repo"

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install jq to parse the weather data."
    echo "For example, on Debian/Ubuntu: sudo apt-get install jq"
    exit 1
fi

# Fetch weather data using curl
echo "Fetching weather data for Laichingen..."
WEATHER_DATA=$(curl -s -H "User-Agent: ${USER_AGENT}" "${API_URL}")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch weather data. Please check your internet connection or the API URL."
    exit 1
fi

# Check if WEATHER_DATA is empty or not valid JSON (simple check)
if [ -z "${WEATHER_DATA}" ] || ! jq -e . >/dev/null 2>&1 <<<"${WEATHER_DATA}"; then
    echo "Error: Failed to get valid weather data. The API might be temporarily unavailable or the response was not JSON."
    # echo "Debug: Received data: ${WEATHER_DATA}" # Uncomment for debugging
    exit 1
fi

# Parse and display weather information
echo "Current Weather in Laichingen:"

# Extract data using jq
# We target the first timeseries entry, as it usually represents the current or very near-future forecast.
CURRENT_TEMP=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.instant.details.air_temperature')
SYMBOL_CODE=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.next_1_hours.summary.symbol_code')
WIND_SPEED=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.instant.details.wind_speed')
WIND_DIRECTION=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.instant.details.wind_from_direction')

# Check if any value is null (jq returns 'null' as a string if the path doesn't exist)
if [ "${CURRENT_TEMP}" = "null" ] || \
   [ "${SYMBOL_CODE}" = "null" ] || \
   [ "${WIND_SPEED}" = "null" ] || \
   [ "${WIND_DIRECTION}" = "null" ]; then
    echo "Error: Could not extract all required weather details from the API response."
    echo "This might be due to changes in the API structure or missing data for the location."
    # echo "Debug: Received data: ${WEATHER_DATA}" # Uncomment for debugging
    exit 1
fi

echo "----------------------------------"
echo "Temperature: ${CURRENT_TEMP}°C"
echo "Weather: ${SYMBOL_CODE}"
echo "Wind Speed: ${WIND_SPEED} m/s"
echo "Wind Direction: ${WIND_DIRECTION}°"
echo "----------------------------------"

exit 0
