#!/bin/bash

# Bash の厳格モードを有効にして、予期しないエラーを早めに検出する
set -euo pipefail

# このスクリプトが置かれているディレクトリを取得する
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# 共通設定ファイルのパスを指定する
CONF_FILE="${SCRIPT_DIR}/../monitor_all.conf"

# 設定ファイルが存在する場合だけ読み込む
if [ -f "${CONF_FILE}" ]; then
    # shellcheck disable=SC1090
    # 設定ファイルの内容を現在のシェルに読み込む
    source "${CONF_FILE}" >/dev/null 2>&1 || true
fi

# ログ出力スクリプトのパスを決定する
# 環境変数 LOG_OUTPUT_SCRIPT があればそれを優先し、なければ既定の log_output.sh を使う
LOG_OUTPUT_SCRIPT_PATH="${LOG_OUTPUT_SCRIPT:-${SCRIPT_DIR}/log_output.sh}"

# 実行対象のログ出力スクリプトが存在するか確認する
if [ ! -f "${LOG_OUTPUT_SCRIPT_PATH}" ]; then
    # 見つからない場合はエラーを出して終了する
    echo "Logger not found: ${LOG_OUTPUT_SCRIPT_PATH}" >&2
    exit 1
fi

# 受け取った引数を実際のログ出力スクリプトへ渡す
"${LOG_OUTPUT_SCRIPT_PATH}" "$1" "$2" "$3"
