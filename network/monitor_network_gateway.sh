#!/bin/bash

# デフォルトゲートウェイへの疎通を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
# 共通関数を読み込む
source "${SCRIPT_DIR}/monitor_network_common.sh"

network_common_init
if ! network_common_validate; then
    network_common_notify_missing network_gateway
    exit 1
fi

GATEWAY=$(ip route show default dev "${INTERFACE}" | awk '/default/ {print $3; exit}')

if [ -z "${GATEWAY}" ]; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway ERROR "GATEWAY_NOT_FOUND"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway ERROR "GATEWAY_NOT_FOUND"
    exit 1
fi

if ping -c 1 -W 1 "${GATEWAY}" >/dev/null 2>&1; then
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway OK "GATEWAY=${GATEWAY}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway OK "GATEWAY=${GATEWAY}"
else
    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway ERROR "GATEWAY_DOWN:${GATEWAY}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway ERROR "GATEWAY_DOWN:${GATEWAY}"
    exit 1
fi
