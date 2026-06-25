#!/bin/bash

# Set the CPU usage threshold from the environment or use the default.
# Use CPU_THRESHOLD in monitor_all.conf to configure this value.
THRESHOLD=${CPU_THRESHOLD:-80}
INTERVAL=${INTERVAL:-1}

# Get the CPU usage from /proc/stat
read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

# Calculate the total and idle CPU time
total1=$((user+nice+system+idle+iowait+irq+softirq+steal))
idle1=$((idle+iowait))

sleep ${INTERVAL}

# Get the CPU usage from /proc/stat
read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat

# Calculate the total and idle CPU time
total2=$((user+nice+system+idle+iowait+irq+softirq+steal))
idle2=$((idle+iowait))


total_diff=$((total2-total1))
idle_diff=$((idle2-idle1))

# Calculate the CPU usage percentage
CPU=$((100*(total_diff-idle_diff)/total_diff))

# Check if the CPU usage exceeds the threshold and send a notification
if [ "$CPU" -ge "$THRESHOLD" ]; then
    ./notify_redis.sh cpu ERROR "$CPU %" 
else
    ./notify_redis.sh cpu OK "$CPU %"
fi
