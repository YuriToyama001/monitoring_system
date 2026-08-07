#!/bin/bash

# 外部ノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

run_monitor_script() {
    local script_path="$1"
    shift
    "${script_path}" "$@" || true
}

# 直接実行された場合のみ子スクリプトを起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_monitor_script "${SCRIPT_DIR}/monitor_poeye_node.sh"
fi

