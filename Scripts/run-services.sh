#!/bin/bash
set -e

# Ensure argument is passed
if [[ $# -ne 1 ]]; then
  echo "❌ Usage: $0 [vault|bao]"
  exit 1
fi

SERVICE="$1"

# Validate the argument
if [[ "$SERVICE" != "vault" && "$SERVICE" != "bao" ]]; then
  echo "❌ Invalid argument: $SERVICE"
  echo "   Must be 'vault' or 'bao'"
  exit 1
fi

COMPOSE_FILE="compose-${SERVICE}.yml"
PROJECT_NAME="$SERVICE"

# Ensure the compose file exists
if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "❌ Compose file '$COMPOSE_FILE' not found!"
  exit 1
fi

echo "🛑 Bringing down Docker Compose services..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" down --volumes --remove-orphans

echo "🧹 Pruning unused Docker networks and volumes..."
docker volume prune -f
docker network prune -f

echo "🚀 Starting Docker Compose services fresh..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up --build -d