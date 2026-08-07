#!/bin/bash

# ネットワーク関連の監視スクリプトをまとめて実行するラッパー
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
COMMON_SCRIPT="${ROOT_DIR}/monitor_common.sh"
CONF_FILE="${ROOT_DIR}/monitor_all.conf"

if [ -f "${CONF_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${CONF_FILE}"
fi

export INTERFACE_1
export INTERFACE_2
export ENABLE_GATEWAY_CHECK_1
export ENABLE_GATEWAY_CHECK_2

source "${COMMON_SCRIPT}"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_monitor_script "${SCRIPT_DIR}/monitor_network_status.sh" "${INTERFACE_1}"
    run_monitor_script "${SCRIPT_DIR}/monitor_network_traffic.sh" "${INTERFACE_1}"

    if [ "${ENABLE_GATEWAY_CHECK_1:-true}" = "true" ]; then
        run_monitor_script "${SCRIPT_DIR}/monitor_network_gateway.sh" "${INTERFACE_1}"
    fi

    if [ -n "${INTERFACE_2:-}" ]; then
        run_monitor_script "${SCRIPT_DIR}/monitor_network_status.sh" "${INTERFACE_2}"
        run_monitor_script "${SCRIPT_DIR}/monitor_network_traffic.sh" "${INTERFACE_2}"

        if [ "${ENABLE_GATEWAY_CHECK_2:-true}" = "true" ]; then
            run_monitor_script "${SCRIPT_DIR}/monitor_network_gateway.sh" "${INTERFACE_2}"
        fi
    fi
fi
