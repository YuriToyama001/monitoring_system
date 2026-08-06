#!/bin/bash

# ネットワーク関連の監視スクリプトをまとめて実行するラッパー
set -euo pipefail

# このスクリプトの配置ディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1090
# 共通関数を読み込む
source "${SCRIPT_DIR}/monitor_network_common.sh"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    "${SCRIPT_DIR}/monitor_network_status.sh"
    "${SCRIPT_DIR}/monitor_network_traffic.sh"
    "${SCRIPT_DIR}/monitor_network_gateway.sh"

fi
