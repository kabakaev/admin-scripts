#!/bin/bash

# User-Agent header for all API requests
USER_AGENT="MyWeatherApp/1.0 github.com/your-username/your-repo-v2" # Updated user agent slightly for clarity

# --- Dependency checks ---
# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "curl could not be found. Please install curl."
    echo "For example, on Debian/Ubuntu: sudo apt-get install curl"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq to parse API responses."
    echo "For example, on Debian/Ubuntu: sudo apt-get install jq"
    exit 1
fi

# --- Argument parsing ---
if [ -z "$1" ]; then
    echo "Usage: ./get_weather.sh <town_name>"
    exit 1
fi
TOWN_NAME="$1"

# --- Geocoding using Nominatim API ---
# URL-encode the town name (requires jq for @uri filter)
ENCODED_TOWN_NAME=$(jq -nr --arg town "${TOWN_NAME}" '$town|@uri')

NOMINATIM_API_URL="https://nominatim.openstreetmap.org/search?q=${ENCODED_TOWN_NAME}&format=jsonv2&limit=1"

echo "Fetching coordinates for ${TOWN_NAME}..."
COORDS_JSON=$(curl -s -H "User-Agent: ${USER_AGENT}" "${NOMINATIM_API_URL}")

# Check if curl command for Nominatim was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch coordinates. Please check your internet connection or the Nominatim API URL."
    exit 1
fi

# Check if COORDS_JSON is empty or not valid JSON
if [ -z "${COORDS_JSON}" ] || ! jq -e . >/dev/null 2>&1 <<<"${COORDS_JSON}"; then
    echo "Error: Failed to get valid JSON data from Nominatim API for ${TOWN_NAME}."
    # echo "Debug: Received data from Nominatim: ${COORDS_JSON}" # Uncomment for debugging
    exit 1
fi

# Extract lat and lon using jq
# Ensure the response is an array and has at least one element
if ! jq -e 'type=="array" and length > 0' >/dev/null <<<"${COORDS_JSON}"; then
    echo "Error: Could not find coordinates for ${TOWN_NAME}. Nominatim returned no results or unexpected format."
    # echo "Debug: Received data from Nominatim: ${COORDS_JSON}" # Uncomment for debugging
    exit 1
fi

LAT=$(echo "${COORDS_JSON}" | jq -r '.[0].lat')
LON=$(echo "${COORDS_JSON}" | jq -r '.[0].lon')

# Check if lat or lon are null or empty (jq returns 'null' as string if path is missing)
if [ "${LAT}" = "null" ] || [ -z "${LAT}" ] || [ "${LON}" = "null" ] || [ -z "${LON}" ]; then
    echo "Error: Could not extract latitude or longitude for ${TOWN_NAME} from Nominatim response."
    # echo "Debug: Received data from Nominatim: ${COORDS_JSON}" # Uncomment for debugging
    exit 1
fi

echo "Coordinates found: Lat=${LAT}, Lon=${LON}"

# --- Weather data using MET Norway API ---
MET_API_URL="https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${LAT}&lon=${LON}"

echo "Fetching weather data for ${TOWN_NAME} (Lat: ${LAT}, Lon: ${LON})..."
WEATHER_DATA=$(curl -s -H "User-Agent: ${USER_AGENT}" "${MET_API_URL}")

# Check if curl command for MET API was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch weather data. Please check your internet connection or the MET Norway API URL."
    exit 1
fi

# Check if WEATHER_DATA is empty or not valid JSON
if [ -z "${WEATHER_DATA}" ] || ! jq -e . >/dev/null 2>&1 <<<"${WEATHER_DATA}"; then
    echo "Error: Failed to get valid weather data from MET Norway API."
    # echo "Debug: Received data from MET API: ${WEATHER_DATA}" # Uncomment for debugging
    exit 1
fi

# --- Parse and display weather information ---
echo "Current Weather in ${TOWN_NAME}:"

CURRENT_TEMP=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.instant.details.air_temperature')
SYMBOL_CODE=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.next_1_hours.summary.symbol_code') # Assuming next_1_hours is desired
WIND_SPEED=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.instant.details.wind_speed')
WIND_DIRECTION=$(echo "${WEATHER_DATA}" | jq -r '.properties.timeseries[0].data.instant.details.wind_from_direction')

# Check if any weather value is null
if [ "${CURRENT_TEMP}" = "null" ] || \
   [ "${SYMBOL_CODE}" = "null" ] || \
   [ "${WIND_SPEED}" = "null" ] || \
   [ "${WIND_DIRECTION}" = "null" ]; then
    echo "Error: Could not extract all required weather details from the MET Norway API response."
    echo "This might be due to changes in the API structure or missing data for the location."
    # echo "Debug: Received data from MET API: ${WEATHER_DATA}" # Uncomment for debugging
    exit 1
fi

echo "----------------------------------"
echo "Temperature: ${CURRENT_TEMP}°C"
echo "Weather: ${SYMBOL_CODE}"
echo "Wind Speed: ${WIND_SPEED} m/s"
echo "Wind Direction: ${WIND_DIRECTION}°"
echo "----------------------------------"

exit 0
