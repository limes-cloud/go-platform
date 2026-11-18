#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

[[ -f .env ]] || { echo "missing .env; copy .env.example and fill it" >&2; exit 1; }

for name in configure manager resource gateway cron ai-agent web-client web-admin; do
  [[ -f "conf/$name.yaml" ]] || { echo "missing conf/$name.yaml; regenerate the deployment package" >&2; exit 1; }
done

[[ -x dist/web-server ]] || { echo "missing dist/web-server; run ./build.sh" >&2; exit 1; }
[[ -f web/client/index.html ]] || { echo "missing web/client/index.html; run ./build-web.sh" >&2; exit 1; }
[[ -f web/admin/index.html ]] || { echo "missing web/admin/index.html; run ./build-admin-web.sh" >&2; exit 1; }
[[ -f web/Dockerfile ]] || { echo "missing web/Dockerfile; run ./build-web.sh" >&2; exit 1; }

# The legacy systemd admin-web is superseded by the platform-web containers.
systemctl stop go-platform-admin-web 2>/dev/null || true
systemctl disable go-platform-admin-web 2>/dev/null || true

if docker compose version >/dev/null 2>&1; then
  COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE=(docker-compose)
else
  echo "Docker Compose v2 is required" >&2
  exit 1
fi

"${COMPOSE[@]}" --env-file .env up -d --build --remove-orphans
"${COMPOSE[@]}" --env-file .env ps

echo "started; run ./verify.sh after the health checks settle"
