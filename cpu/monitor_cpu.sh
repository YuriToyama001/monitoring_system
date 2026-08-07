#!/bin/bash

# CPU 関連の監視スクリプトをまとめて実行するラッパー
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
COMMON_SCRIPT="${ROOT_DIR}/monitor_common.sh"
# shellcheck disable=SC1090

source "${COMMON_SCRIPT}"

# 直接実行された場合のみ子スクリプトを起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_monitor_script "${SCRIPT_DIR}/monitor_cpu_usage.sh"
    run_monitor_script "${SCRIPT_DIR}/monitor_cpu_temp.sh"
fi
