#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

[[ -f .env ]] || { echo "missing .env; copy .env.example and fill it" >&2; exit 1; }

for name in configure manager resource gateway; do
  [[ -f "conf/$name.yaml" ]] || { echo "missing conf/$name.yaml; regenerate the deployment package" >&2; exit 1; }
done

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Docker Compose v2 is required" >&2
  exit 1
fi

"${COMPOSE[@]}" --env-file .env pull
"${COMPOSE[@]}" --env-file .env up -d --remove-orphans
"${COMPOSE[@]}" --env-file .env ps

echo "started; run ./verify.sh after the health checks settle"
