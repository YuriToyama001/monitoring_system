#!/bin/bash

# メモリ監視スクリプトをまとめて実行するラッパー
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
COMMON_SCRIPT="${ROOT_DIR}/monitor_common.sh"

source "${COMMON_SCRIPT}"

# 直接実行された場合のみメモリ監視を起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_script_check "${SCRIPT_DIR}/monitor_memory_usage.sh"
fi