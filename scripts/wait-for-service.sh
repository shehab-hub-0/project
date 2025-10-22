#!/usr/bin/env bash
# scripts/wait-for-service.sh
# Wait for a TCP host:port or HTTP URL to respond
# Usage:
#  scripts/wait-for-service.sh http://localhost:8080 60
#  scripts/wait-for-service.sh tcp://localhost:9092 60
set -euo pipefail

TARGET="${1:-}"
TIMEOUT="${2:-60}"
SLEEP=2
START=$(date +%s)

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 <url or tcp://host:port> [timeout_seconds]"
  exit 1
fi

until {
  if [[ "$TARGET" =~ ^tcp:// ]]; then
    # tcp check
    hostport="${TARGET#tcp://}"
    host="${hostport%%:*}"
    port="${hostport##*:}"
    (echo > /dev/tcp/"$host"/"$port") >/dev/null 2>&1
  else
    # http check
    curl -fsS "$TARGET" >/dev/null 2>&1
  fi
}; do
  now=$(date +%s)
  elapsed=$((now - START))
  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    echo "Timeout waiting for $TARGET after ${TIMEOUT}s"
    exit 1
  fi
  echo "Waiting for $TARGET..."
  sleep $SLEEP
done

echo "$TARGET is available"
