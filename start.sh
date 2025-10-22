#!/usr/bin/env bash
# start.sh
# Bring up the docker-compose environment and perform initialization steps:
#  - start containers
#  - wait for health endpoints
#  - initialize Hive metastore schema (Postgres)
#  - create default Kafka topics
#  - print local and ngrok UI URLs
#
# Usage:
#   ./start.sh

set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export COMPOSE_PROJECT_NAME=bigdataws

# Load .env if present
if [ -f "${ROOT_DIR}/.env" ]; then
  echo "Loading .env"
  set -o allexport
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/.env"
  set +o allexport
fi

echo "Starting docker-compose..."
docker-compose up -d

# Utility to wait for http service
wait_for_http() {
  local name=$1
  local url=$2
  local retries=60
  local wait=5
  echo "Waiting for $name at $url"
  for i in $(seq 1 $retries); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo "$name is available"
      return 0
    fi
    sleep $wait
  done
  echo "Timed out waiting for $name"
  return 1
}

# Wait for critical services
wait_for_http "Postgres (pg_isready)" "http://localhost:5432" || true
# Using pg_isready inside container for robust check
echo "Waiting for Postgres to be ready..."
docker-compose exec -T postgres bash -c 'until pg_isready -U hive; do sleep 2; done' || true

wait_for_http "HDFS NameNode UI" "http://localhost:9870"
wait_for_http "YARN RM UI" "http://localhost:8088"
wait_for_http "Spark Master UI" "http://localhost:8080"
wait_for_http "Spark Worker UI" "http://localhost:8081"
wait_for_http "HiveServer2" "http://localhost:10000" || true
wait_for_http "Kafka Broker (via Kafdrop)" "http://localhost:9000" || true

echo "Initializing Hive metastore schema (if not already initialized)..."
# init/init-metastore.sql is mounted into postgres container and will be executed by postgres on first start
# But in case Postgres already exists, ensure schema user has privileges.
docker-compose exec -T postgres psql -U hive -d hive -c "SELECT tablename FROM pg_tables LIMIT 1;" >/dev/null 2>&1 || true

# Create default Kafka topic(s)
echo "Creating Kafka topic: ${KAFKA_TOPIC:-example-topic}"
# Use kafka container to create topic
docker-compose exec -T kafka bash -lc " \
/opt/kafka/bin/kafka-topics.sh --create --if-not-exists --bootstrap-server kafka:9092 \
--replication-factor ${KAFKA_REPLICATION:-1} --partitions ${KAFKA_PARTITIONS:-1} --topic ${KAFKA_TOPIC:-example-topic} || true"

echo "Listing topics:"
docker-compose exec -T kafka bash -lc "/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka:9092" || true

# If NGROK_AUTH_TOKEN is set, create ngrok tunnels for main UIs by running ngrok in container
if [ -n "${NGROK_AUTH_TOKEN:-}" ]; then
  echo "NGROK_AUTH_TOKEN provided, creating ngrok tunnels..."
  # configure token in container
  docker-compose exec -T ngrok sh -c "mkdir -p /root/.ngrok2 && printf 'authtoken: %s\n' '${NGROK_AUTH_TOKEN}' > /root/.ngrok2/ngrok.yml"
  # create background tunnels using ngrok client (if image has curl+ngrok client)
  # we will run tunnels for NameNode, Spark Master, Spark UI (8080), Kafdrop (9000)
  docker-compose exec -d ngrok sh -c "ngrok http 9870 & ngrok http 8080 & ngrok http 9000 || true"
  echo "Launched ngrok inside ngrok container. Use docker-compose logs ngrok to find public URLs (or inspect ngrok console inside container)."
else
  echo "NGROK_AUTH_TOKEN not set. Skipping ngrok tunnels."
fi

echo
echo "==== ACCESS UI ENDPOINTS (local) ===="
echo "HDFS NameNode UI: http://localhost:9870"
echo "YARN ResourceManager UI: http://localhost:8088"
echo "Spark Master UI: http://localhost:8080"
echo "Spark Worker UI: http://localhost:8081"
echo "Hive Metastore (Thrift): thrift://localhost:9083"
echo "HiveServer2 (Beeline): jdbc:hive2://localhost:10000"
echo "Kafka Broker: localhost:9092"
echo "Kafdrop (Kafka UI): http://localhost:9000"
echo
echo "To view logs: docker-compose logs -f <service>"
echo "Example: docker-compose logs -f hive"
echo
echo "Repository start complete."
