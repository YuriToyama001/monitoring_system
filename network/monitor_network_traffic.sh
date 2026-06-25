#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
source "${SCRIPT_DIR}/monitor_network_common.sh"

network_common_init
if ! network_common_validate; then
    network_common_notify_missing network_traffic
    exit 1
fi

INTERVAL=${INTERVAL:-1}
THRESHOLD_PERCENT=${NETWORK_TRAFFIC_THRESHOLD:-80}

SPEED=$(cat "${BASE}/speed" 2>/dev/null)

if ! [[ "${SPEED}" =~ ^[0-9]+$ ]]; then
    "${SCRIPT_DIR}/../notify/notify_redis.sh" network_traffic ERROR "SPEED_UNKNOWN"
    exit 1
fi

RX1=$(cat ${BASE}/statistics/rx_bytes)
TX1=$(cat ${BASE}/statistics/tx_bytes)

sleep ${INTERVAL}

RX2=$(cat ${BASE}/statistics/rx_bytes)
TX2=$(cat ${BASE}/statistics/tx_bytes)

RX_BYTES=$((RX2 - RX1))
TX_BYTES=$((TX2 - TX1))

RX_MBPS=$((RX_BYTES * 8 / 1000 / 1000))
TX_MBPS=$((TX_BYTES * 8 / 1000 / 1000))

RX_PERCENT=$((RX_MBPS * 100 / SPEED))
TX_PERCENT=$((TX_MBPS * 100 / SPEED))

MAX_PERCENT=$(( RX_PERCENT > TX_PERCENT ? RX_PERCENT : TX_PERCENT ))
VALUE="RX=${RX_MBPS}Mbps,TX=${TX_MBPS}Mbps"

if [ "${MAX_PERCENT}" -ge "${THRESHOLD_PERCENT}" ]; then
    "${SCRIPT_DIR}/../notify/notify_redis.sh" network_traffic ERROR "${VALUE}"
else
    "${SCRIPT_DIR}/../notify/notify_redis.sh" network_traffic OK "${VALUE}"
fi
