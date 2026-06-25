#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Monitor memory usage and send notification to Redis if it exceeds threshold
# Use MEMORY_THRESHOLD in monitor_all.conf to configure this value.
THRESHOLD=${MEMORY_THRESHOLD:-90}

# Get total and available memory in kilobytes
TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)

# Calculate used memory and percentage
USED=$((TOTAL-AVAILABLE))
PERCENT=$((USED*100/TOTAL))

# Check if the used memory percentage exceeds the threshold
if [ "$PERCENT" -ge "$THRESHOLD" ]; then
    ${SCRIPT_DIR}/../notify/notify_redis.sh memory ERROR "$PERCENT"
else
    ${SCRIPT_DIR}/../notify/notify_redis.sh memory OK "$PERCENT"
fi