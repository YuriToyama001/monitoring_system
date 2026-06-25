#!/bin/bash

# Monitor network interface status and send notification to Redis if it is down or has issues
INTERFACE=eth0

# Set the base path for the network interface
BASE=/sys/class/net/${INTERFACE}

# Check if the network interface exists
if [ ! -d "${BASE}" ]; then
    ./notify_redis.sh network ERROR "IF_NOT_FOUND"
    exit 1
fi

# Physical link status
CARRIER=$(cat ${BASE}/carrier 2>/dev/null)
# Operational state of the network interface
OPERSTATE=$(cat ${BASE}/operstate 2>/dev/null)

# Check if the carrier is down (no link)
if [ "${CARRIER}" = "0" ]; then
    ./notify_redis.sh network ERROR "LINK_DOWN"
    exit 1
fi

# Check the operational state of the network interface
case "${OPERSTATE}" in
    up)
        ./notify_redis.sh network OK "LINK_UP"
        ;;
    down)
        ./notify_redis.sh network ERROR "IF_DOWN"
        ;;
    dormant)
        ./notify_redis.sh network ERROR "IF_DORMANT"
        ;;
    lowerlayerdown)
        ./notify_redis.sh network ERROR "LOWER_LAYER_DOWN"
        ;;
    testing)
        ./notify_redis.sh network ERROR "TESTING"
        ;;
    unknown)
        ./notify_redis.sh network WARNING "STATE_UNKNOWN"
        ;;
    *)
        ./notify_redis.sh network WARNING "STATE_${OPERSTATE}"
        ;;
esac