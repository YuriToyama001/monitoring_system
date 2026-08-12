#!/bin/bash

# 外部ノードへの疎通確認を行うスクリプト
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
COMMON_SCRIPT="${ROOT_DIR}/monitor_common.sh"

source "${COMMON_SCRIPT}"

# 直接実行された場合のみ子スクリプトを起動する
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_script_check "${SCRIPT_DIR}/monitor_poeye_node.sh"
fi