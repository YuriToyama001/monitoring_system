#!/bin/bash

# ネットワーク監視スクリプトで共通して使う関数を定義する
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

network_common_init() {
    INTERFACES=()

    local interface_1="${INTERFACE_1:-${INTERFACE:-}}"
    local interface_2="${INTERFACE_2:-}"

    if [ -n "${interface_1}" ]; then
        INTERFACES+=("${interface_1}")
    fi

    if [ -n "${interface_2}" ]; then
        INTERFACES+=("${interface_2}")
    fi

    if [ "${#INTERFACES[@]}" -eq 0 ]; then
        INTERFACES=("eth0")
    fi

    INTERFACE="${INTERFACES[0]}"
    BASE="/sys/class/net/${INTERFACE}"
}

network_common_validate() {
    local target_interface="${1:-${INTERFACE}}"
    [ -d "/sys/class/net/${target_interface}" ]
}

network_common_gateway_check_enabled() {
    local interface_index="$1"
    local config_var="ENABLE_GATEWAY_CHECK_${interface_index}"
    local value="${!config_var:-${ENABLE_GATEWAY_CHECK:-true}}"

    case "${value,,}" in
        1|true|yes|on)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

network_common_notify_missing() {
    local event="$1"
    notify_redis "${event}" ERROR "IF_NOT_FOUND"
}
