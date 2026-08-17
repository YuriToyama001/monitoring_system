#!/bin/bash

# 通知の共通入口。設定に応じて実際の通知先を切り替える
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONF_FILE="${SCRIPT_DIR}/../monitor_all.conf"

if [ -f "${CONF_FILE}" ]; then
    # shellcheck disable=SC1090
    source "${CONF_FILE}" >/dev/null 2>&1 || true
fi

NOTIFY_SCRIPT_PATH="${NOTIFY_SCRIPT:-}"

if [ -z "${NOTIFY_SCRIPT_PATH}" ]; then
    NOTIFY_SCRIPT_PATH="${SCRIPT_DIR}/notify_dummy.sh"
elif [[ "${NOTIFY_SCRIPT_PATH}" != /* ]]; then
    NOTIFY_SCRIPT_PATH="${SCRIPT_DIR}/${NOTIFY_SCRIPT_PATH}"
fi

if [ ! -f "${NOTIFY_SCRIPT_PATH}" ]; then
    echo "Notifier not found: ${NOTIFY_SCRIPT_PATH}" >&2
    exit 1
fi

"${NOTIFY_SCRIPT_PATH}" "$1" "$2" "$3"