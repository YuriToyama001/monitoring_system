#!/bin/bash

# 監視イベントを syslog へ送信するログ出力スクリプト
set -euo pipefail

# 引数からリソース名・状態・値を受け取る
RESOURCE=${1:-unknown}
STATUS=${2:-unknown}
VALUE=${3:-}

TIMESTAMP=$(date '+%F %T')

MESSAGE="${TIMESTAMP} resource=${RESOURCE} status=${STATUS} value=${VALUE}"

if command -v logger >/dev/null 2>&1; then
    logger -t monitoring_system "${MESSAGE}"
else
    echo "logger command not available" >&2
    exit 1
fi
