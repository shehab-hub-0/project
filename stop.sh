#!/usr/bin/env bash
# stop.sh
# Stop docker-compose, collect some logs into ./logs for troubleshooting, and gracefully remove containers.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${ROOT_DIR}/logs"
SERVICES=(postgres kafka hive namenode datanode resourcemanager spark-master spark-worker kafdrop zookeeper ngrok)

echo "Collecting logs..."
for s in "${SERVICES[@]}"; do
  echo "---- logs for $s ----" > "${ROOT_DIR}/logs/${s}.log"
  docker-compose logs --no-color "$s" >> "${ROOT_DIR}/logs/${s}.log" || true
done

echo "Stopping containers..."
docker-compose down

echo "Logs saved to ./logs/"
