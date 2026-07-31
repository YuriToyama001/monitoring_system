#!/bin/bash

# 監視イベントをファイルへ出力するログ出力スクリプト
set -euo pipefail

# 引数からリソース名・状態・値を受け取る
RESOURCE=${1:-unknown}
STATUS=${2:-unknown}
VALUE=${3:-}

TIMESTAMP=$(date '+%F %T')

LOG_DIR=${LOG_DIR:-/var/log/monitor}
LOG_FILE=${LOG_FILE:-${LOG_DIR}/monitor.log}

if [[ "${LOG_DIR}" != /* ]]; then
  LOG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)/${LOG_DIR}"
fi

mkdir -p "${LOG_DIR}" 2>/dev/null || {
  echo "Error: cannot create log directory ${LOG_DIR}" >&2
  exit 1
}

if [ ! -w "${LOG_DIR}" ]; then
  echo "Error: cannot write to ${LOG_DIR}" >&2
  exit 1
fi

if [ -e "${LOG_FILE}" ] && [ ! -w "${LOG_FILE}" ]; then
  echo "Error: cannot write to ${LOG_FILE}" >&2
  exit 1
fi

if ! printf '%s resource=%s status=%s message:%s\n' "${TIMESTAMP}" "${RESOURCE}" "${STATUS}" "${VALUE}" >> "${LOG_FILE}"; then
  echo "Error: failed to write log entry to ${LOG_FILE}" >&2
  exit 1
fi
