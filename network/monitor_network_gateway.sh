#!/bin/bash

# デフォルトゲートウェイへの疎通を確認するスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
# 共通関数を読み込む
source "${SCRIPT_DIR}/monitor_network_common.sh"

network_common_init

for interface_index in "${!INTERFACES[@]}"; do
    target_interface="${INTERFACES[${interface_index}]}"
    INTERFACE="${target_interface}"
    BASE="/sys/class/net/${INTERFACE}"

    if ! network_common_gateway_check_enabled "$((interface_index + 1))"; then
        continue
    fi

    if ! network_common_validate "${INTERFACE}"; then
        network_common_notify_missing network_gateway
        continue
    fi

    GATEWAY=$(ip route show default dev "${INTERFACE}" | awk '/default/ {print $3; exit}')

    if [ -z "${GATEWAY}" ]; then
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway ERROR "GATEWAY_NOT_FOUND:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway ERROR "GATEWAY_NOT_FOUND:${INTERFACE}"
        continue
    fi

    if ping -c 1 -W 1 "${GATEWAY}" >/dev/null 2>&1; then
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway OK "GATEWAY=${GATEWAY}:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway OK "GATEWAY=${GATEWAY}:${INTERFACE}"
    else
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" network_gateway ERROR "GATEWAY_DOWN:${GATEWAY}:${INTERFACE}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" network_gateway ERROR "GATEWAY_DOWN:${GATEWAY}:${INTERFACE}"
    fi
done
