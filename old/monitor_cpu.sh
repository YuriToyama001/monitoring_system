#!/bin/bash

THRESHOLD=80

IDLE=$(top -bn2 | grep "Cpu(s)" | tail -1 | awk '{print $8}' | cut -d. -f1)

CPU=$((100-IDLE))

if [ "$CPU" -ge "$THRESHOLD" ]; then
	echo "cpu error"
else
	echo "cpu ok"
fi
