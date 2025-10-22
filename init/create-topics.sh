#!/usr/bin/env bash
# init/create-topics.sh
# Helper script to create Kafka topics from the host or from workspace container.
# Usage:
#   ./init/create-topics.sh my-topic 3 1
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <topic> [partitions] [replication]"
  exit 2
fi

TOPIC="$1"
PARTITIONS="${2:-1}"
REPLICATION="${3:-1}"

echo "Creating topic ${TOPIC} (partitions=${PARTITIONS}, replication=${REPLICATION})..."
docker-compose exec -T kafka bash -lc "/opt/kafka/bin/kafka-topics.sh --create --if-not-exists --bootstrap-server kafka:9092 --replication-factor ${REPLICATION} --partitions ${PARTITIONS} --topic ${TOPIC}"
echo "Topic created (or already existed)."
