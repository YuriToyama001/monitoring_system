#!/bin/bash
set -euo pipefail

# Unified monitoring script for CPU, memory, external node, network status, and network traffic.
# This script runs all checks in a single shell process.

INTERFACE=${INTERFACE:-eth0}
HOST=${HOST:-172.16.1.151}
CPU_THRESHOLD=${CPU_THRESHOLD:-80}
MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-90}
NETWORK_TRAFFIC_THRESHOLD=${NETWORK_TRAFFIC_THRESHOLD:-80}
INTERVAL_SECS=${INTERVAL_SECS:-1}
REDIS_HOST=${REDIS_HOST:-127.0.0.1}
REDIS_PORT=${REDIS_PORT:-6379}

notify_redis() {
    local resource="$1"
    local status="$2"
    local value="$3"
    local timestamp

    timestamp=$(date '+%F %T')

    # Replace the following lines with actual Redis commands if needed.
    echo "Resource: ${resource}, Status: ${status}, Value: ${value}, Timestamp: ${timestamp}"
}

meminfo_value() {
    awk -v key="$1" '$1 == key {print $2; exit}' /proc/meminfo
}

monitor_cpu() {
    local cpu user nice system idle iowait irq softirq steal guest guest_nice
    local total1 idle1 total2 idle2 total_diff idle_diff CPU

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle1=$((idle + iowait))

    sleep "${INTERVAL_SECS}"

    read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle2=$((idle + iowait))

    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))
    CPU=$((100 * (total_diff - idle_diff) / total_diff))

    if [ "${CPU}" -ge "${CPU_THRESHOLD}" ]; then
        notify_redis cpu ERROR "${CPU}%"
    else
        notify_redis cpu OK "${CPU}%"
    fi
}

monitor_memory() {
    local total available used percent

    total=$(meminfo_value MemTotal)
    available=$(meminfo_value MemAvailable)
    used=$((total - available))
    percent=$((used * 100 / total))

    if [ "${percent}" -ge "${MEMORY_THRESHOLD}" ]; then
        notify_redis memory ERROR "${percent}%"
    else
        notify_redis memory OK "${percent}%"
    fi
}

monitor_external_node() {
    if ! ping -c 1 -W 1 "${HOST}" >/dev/null 2>&1; then
        notify_redis nodeA ERROR "PING_FAIL"
        return
    fi

    notify_redis nodeA OK "NORMAL"
}

monitor_network() {
    local base carrier operstate

    base="/sys/class/net/${INTERFACE}"
    if [ ! -d "${base}" ]; then
        notify_redis network ERROR "IF_NOT_FOUND"
        return
    fi

    carrier=$(cat "${base}/carrier" 2>/dev/null || echo "0")
    operstate=$(cat "${base}/operstate" 2>/dev/null || echo "unknown")

    if [ "${carrier}" = "0" ]; then
        notify_redis network ERROR "LINK_DOWN"
        return
    fi

    case "${operstate}" in
        up)
            notify_redis network OK "LINK_UP"
            ;;
        down)
            notify_redis network ERROR "IF_DOWN"
            ;;
        dormant)
            notify_redis network ERROR "IF_DORMANT"
            ;;
        lowerlayerdown)
            notify_redis network ERROR "LOWER_LAYER_DOWN"
            ;;
        testing)
            notify_redis network ERROR "TESTING"
            ;;
        unknown)
            notify_redis network WARNING "STATE_UNKNOWN"
            ;;
        *)
            notify_redis network WARNING "STATE_${operstate}"
            ;;
    esac
}

monitor_network_traffic() {
    local base speed rx1 tx1 rx2 tx2 rx_bytes tx_bytes rx_mbps tx_mbps rx_percent tx_percent max_percent

    base="/sys/class/net/${INTERFACE}"
    if [ ! -d "${base}" ]; then
        notify_redis network ERROR "IF_NOT_FOUND"
        return
    fi

    speed=$(cat "${base}/speed" 2>/dev/null || echo "")
    if ! [[ "${speed}" =~ ^[0-9]+$ ]]; then
        notify_redis network ERROR "SPEED_UNKNOWN"
        return
    fi

    rx1=$(cat "${base}/statistics/rx_bytes")
    tx1=$(cat "${base}/statistics/tx_bytes")

    sleep "${INTERVAL_SECS}"

    rx2=$(cat "${base}/statistics/rx_bytes")
    tx2=$(cat "${base}/statistics/tx_bytes")

    rx_bytes=$((rx2 - rx1))
    tx_bytes=$((tx2 - tx1))
    rx_mbps=$((rx_bytes * 8 / 1000 / 1000))
    tx_mbps=$((tx_bytes * 8 / 1000 / 1000))
    rx_percent=$((rx_mbps * 100 / speed))
    tx_percent=$((tx_mbps * 100 / speed))
    max_percent=$((rx_percent > tx_percent ? rx_percent : tx_percent))

    notify_redis network "${max_percent} >= ${NETWORK_TRAFFIC_THRESHOLD}" "RX=${rx_mbps}Mbps,TX=${tx_mbps}Mbps"

    if [ "${max_percent}" -ge "${NETWORK_TRAFFIC_THRESHOLD}" ]; then
        notify_redis network ERROR "RX=${rx_mbps}Mbps,TX=${tx_mbps}Mbps"
    else
        notify_redis network OK "RX=${rx_mbps}Mbps,TX=${tx_mbps}Mbps"
    fi
}

main() {
    monitor_cpu
    monitor_memory
    monitor_external_node
    monitor_network
    monitor_network_traffic
}

main "$@"
