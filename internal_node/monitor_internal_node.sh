#!/bin/bash

# 外部ノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)

# 共通スクリプトの読み込み
COMMON_SCRIPT="${ROOT_DIR}/monitor_common.sh"
source "${COMMON_SCRIPT}"

# 直接実行された場合のみ子スクリプトを起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_script_check "${SCRIPT_DIR}/monitor_ur_node.sh"
    run_script_check "${SCRIPT_DIR}/monitor_plc_node.sh"
    run_script_check "${SCRIPT_DIR}/monitor_rh_node.sh"
fi