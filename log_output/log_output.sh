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

mkdir -p "${LOG_DIR}" 2>/dev/null || {
  LOG_DIR="${HOME:-/tmp}/.monitor"
  LOG_FILE="${LOG_DIR}/monitor.log"
  mkdir -p "${LOG_DIR}" || exit 1
}

if [ ! -w "${LOG_DIR}" ]; then
  echo "Cannot write to ${LOG_DIR}" >&2
  exit 1
fi

printf '%s resource=%s status=%s value=%s\n' "${TIMESTAMP}" "${RESOURCE}" "${STATUS}" "${VALUE}" >> "${LOG_FILE}"
