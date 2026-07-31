#!/bin/bash

# 監視イベントを Redis へ通知するためのスクリプト
RESOURCE=$1
STATUS=$2
VALUE=$3

# Redis 接続先の設定
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

TIMESTAMP=$(date '+%F %T')

# redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} \
# HSET system:status:${RESOURCE} \
# status "${STATUS}" \
# value "${VALUE}" \
# timestamp "${TIMESTAMP}"

# # イベント履歴
# redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} \
# XADD system:event '*' \
# resource "${RESOURCE}" \
# status "${STATUS}" \
# value "${VALUE}" \
# timestamp "${TIMESTAMP}"
