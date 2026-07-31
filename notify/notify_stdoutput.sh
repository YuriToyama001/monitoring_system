#!/bin/bash

# 監視イベントを Redis へ通知するためのスクリプト
RESOURCE=$1
STATUS=$2
VALUE=$3

TIMESTAMP=$(date '+%F %T')

echo "Timestamp: ${TIMESTAMP}, Resource: ${RESOURCE}, Status: ${STATUS}, Value: ${VALUE}"