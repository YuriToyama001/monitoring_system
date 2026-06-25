#!/bin/bash

# interface to monitor
INTERFACE=${INTERFACE:-eth0}
# monitoring interval in seconds
INTERVAL=${INTERVAL:-1}

# threshold percentage of NIC speed to trigger an alert
THRESHOLD_PERCENT=${NETWORK_TRAFFIC_THRESHOLD:-80}

BASE=/sys/class/net/${INTERFACE}

# Check if the network interface exists
if [ ! -d "${BASE}" ]; then
    ./notify_redis.sh network ERROR "IF_NOT_FOUND"
    exit 1
fi

# link speed in Mbps
SPEED=$(cat ${BASE}/speed 2>/dev/null)

# Check if the speed is a valid number
if ! [[ "$SPEED" =~ ^[0-9]+$ ]]; then
    ./notify_redis.sh network ERROR "SPEED_UNKNOWN"
    exit 1
fi

# Get initial RX and TX byte counts
RX1=$(cat ${BASE}/statistics/rx_bytes)
TX1=$(cat ${BASE}/statistics/tx_bytes)

sleep ${INTERVAL}

# Get RX and TX byte counts after the interval
RX2=$(cat ${BASE}/statistics/rx_bytes)
TX2=$(cat ${BASE}/statistics/tx_bytes)

# Calculate the difference in RX and TX bytes
RX_BYTES=$((RX2 - RX1))
TX_BYTES=$((TX2 - TX1))

# calculate RX and TX in Mbps
RX_MBPS=$((RX_BYTES * 8 / 1000 / 1000))
TX_MBPS=$((TX_BYTES * 8 / 1000 / 1000))

# Calculate RX and TX percentage of the NIC speed
RX_PERCENT=$((RX_MBPS * 100 / SPEED))
TX_PERCENT=$((TX_MBPS * 100 / SPEED))

MAX_PERCENT=$(( RX_PERCENT > TX_PERCENT ? RX_PERCENT : TX_PERCENT ))

# Prepare the notification message
VALUE="RX=${RX_MBPS}Mbps,TX=${TX_MBPS}Mbps"

# Check if the maximum percentage exceeds the threshold and send a notification
if [ "$MAX_PERCENT" -ge "$THRESHOLD_PERCENT" ]; then
    ./notify_redis.sh network ERROR "$VALUE"
else
    ./notify_redis.sh network OK "$VALUE"
fi