#!/bin/bash

# 外部ノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 外部ノードのホスト名。monitor_all.conf で設定可能
HOST=${POEYE_HOST:-}

main() {
    if ! ping -c 1 -W 1 "${HOST}" >/dev/null
    then
        "${SCRIPT_DIR}/../notify/notify_dispatch.sh" PO-EYE ERROR "PING_FAIL:${HOST}"
        "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" PO-EYE ERROR "PING_FAIL:${HOST}"
        exit 1
    fi

    # if ! curl -fs http://${HOST}:8080/health >/dev/null
    # then
    #     ${SCRIPT_DIR}/../notify/notify_dispatch.sh PO-EYE ERROR "SERVICE_FAIL"
    #     exit 1
    # fi

    "${SCRIPT_DIR}/../notify/notify_dispatch.sh" PO-EYE OK "PING_OK:${HOST}"
    "${SCRIPT_DIR}/../log_output/log_output_dispatch.sh" PO-EYE OK "PING_OK:${HOST}"
}

main