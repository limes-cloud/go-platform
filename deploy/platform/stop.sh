#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

# Stop the legacy systemd admin-web left behind by older releases.
systemctl stop go-platform-admin-web 2>/dev/null || true

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Docker Compose v2 is required" >&2
  exit 1
fi

"${COMPOSE[@]}" --env-file .env down --remove-orphans
