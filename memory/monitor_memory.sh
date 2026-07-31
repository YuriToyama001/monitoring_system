#!/bin/bash

# メモリ監視スクリプトをまとめて実行するラッパー
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 直接実行された場合のみメモリ監視を起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${SCRIPT_DIR}/monitor_memory_usage.sh"
fi