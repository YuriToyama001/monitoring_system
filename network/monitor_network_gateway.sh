#!/bin/bash

# デフォルトゲートウェイへの疎通を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090

INTERFACE="${1:-eth0}"

BASE="/sys/class/net/${INTERFACE}"

if [ ! -d "${BASE}" ]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway FAITAL "IF_NOT_FOUND:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway FAITAL "IF_NOT_FOUND:${INTERFACE}"
    exit 1
fi

GATEWAY=$(ip route show default dev "${INTERFACE}" | awk '/default/ {print $3; exit}')

if [ -z "${GATEWAY}" ]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway FAITAL "GATEWAY_NOT_FOUND:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway FAITAL "GATEWAY_NOT_FOUND:${INTERFACE}"
    exit 1
fi

if ping -c 1 -W 1 "${GATEWAY}" >/dev/null 2>&1; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway OK "GATEWAY=${GATEWAY}:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway OK "GATEWAY=${GATEWAY}:${INTERFACE}"
else
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway ERROR "PING_FAILED:${GATEWAY}:${INTERFACE}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway ERROR "PING_FAILED:${GATEWAY}:${INTERFACE}"
fi
