#!/bin/bash

# URノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# URノードのホスト名。monitor_all.conf で設定可能
UR_HOST=${UR_HOST:-}
UR_PORTS=${UR_PORTS:-}

notify_and_log() {
    local status="$1"
    local message="$2"

    #OKなら通知しない
    if [ "${status}" = "OK" ]; then return; fi

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" UR "${status}" "${message}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" UR "${status}" "${message}"
}

ping_check() {
    local host=$1
    if ! ping -c 1 -W 1 "${host}" >/dev/null
    then
        notify_and_log "ERROR" "PING_FAIL HOST=${host}"
        return
    fi

    notify_and_log "OK" "PING_OK HOST=${host}"
    return
}

port_check() {
    local host=$1
    local port=$2
    if ! nc -z -w 1 "${host}" "${port}" >/dev/null
    then
        notify_and_log "ERROR" "PORT_FAIL HOST=${host} PORT=${port}"
        return
        # 複数のポートをチェックするためにexit 1は入れないこと
    fi

    notify_and_log "OK" "PORT_OK HOST=${host} PORT=${port}"
    return
}

main() {
    ping_check "${UR_HOST}"

    for UR_PORT in ${UR_PORTS}; do
        echo UR_PORT: "${UR_PORT}"
        port_check "${UR_HOST}" "${UR_PORT}"
    done
}

main