#!/bin/bash

# メモリ監視スクリプトをまとめて実行するラッパー
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

run_monitor_script() {
    local script_path="$1"
    shift
    "${script_path}" "$@" || true
}

# 直接実行された場合のみメモリ監視を起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_monitor_script "${SCRIPT_DIR}/monitor_memory_usage.sh"
fi