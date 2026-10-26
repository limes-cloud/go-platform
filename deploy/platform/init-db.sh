#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

[[ -f .env ]] || { echo "missing .env; copy .env.example and fill it" >&2; exit 1; }

set -a
# shellcheck disable=SC1091
source .env
set +a

: "${PLATFORM_MYSQL_ADMIN_USER:?PLATFORM_MYSQL_ADMIN_USER is required}"
: "${PLATFORM_MYSQL_ADMIN_PASSWORD:?PLATFORM_MYSQL_ADMIN_PASSWORD is required}"
: "${PLATFORM_MANAGER_DB_PASSWORD:?PLATFORM_MANAGER_DB_PASSWORD is required}"
: "${PLATFORM_CONFIGURE_DB_PASSWORD:?PLATFORM_CONFIGURE_DB_PASSWORD is required}"
: "${PLATFORM_RESOURCE_DB_PASSWORD:?PLATFORM_RESOURCE_DB_PASSWORD is required}"
: "${PLATFORM_GATEWAY_DB_PASSWORD:?PLATFORM_GATEWAY_DB_PASSWORD is required}"

MYSQL_BIN="${PLATFORM_MYSQL_BIN:-mysql}"
command -v "$MYSQL_BIN" >/dev/null 2>&1 || { echo "mysql client not found: $MYSQL_BIN" >&2; exit 1; }

export MYSQL_PWD="$PLATFORM_MYSQL_ADMIN_PASSWORD"
MYSQL=("$MYSQL_BIN" -h "${PLATFORM_DB_HOST:-127.0.0.1}" -P "${PLATFORM_DB_PORT:-3306}" \
  -u "$PLATFORM_MYSQL_ADMIN_USER" --protocol=TCP --default-character-set=utf8mb4)

"${MYSQL[@]}" -e 'SELECT 1' >/dev/null || {
  echo "cannot connect to MySQL as $PLATFORM_MYSQL_ADMIN_USER" >&2
  exit 1
}

validate_ident() {
  [[ "$1" =~ ^[A-Za-z0-9_]+$ ]] || { echo "invalid identifier: $1" >&2; exit 1; }
}

validate_password() {
  [[ "$1" =~ ^[A-Za-z0-9._@%+-]+$ ]] || {
    echo "unsupported password characters; use A-Z a-z 0-9 . _ @ % + -" >&2
    exit 1
  }
}

create_db_user() {
  local db="$1" user="$2" pass="$3"
  validate_ident "$db"
  validate_ident "$user"
  validate_password "$pass"
  echo "==> database/user ${db} <- ${user}"
  "${MYSQL[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${db}\`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${user}'@'127.0.0.1' IDENTIFIED BY '${pass}';
ALTER USER '${user}'@'127.0.0.1' IDENTIFIED BY '${pass}';
GRANT ALL PRIVILEGES ON \`${db}\`.* TO '${user}'@'127.0.0.1';
CREATE USER IF NOT EXISTS '${user}'@'localhost' IDENTIFIED BY '${pass}';
ALTER USER '${user}'@'localhost' IDENTIFIED BY '${pass}';
GRANT ALL PRIVILEGES ON \`${db}\`.* TO '${user}'@'localhost';
FLUSH PRIVILEGES;
SQL
}

table_count() {
  local db="$1"
  "${MYSQL[@]}" -N -B -e \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${db}'"
}

import_schema_if_empty() {
  local db="$1" file="$2"
  [[ -f "$file" ]] || { echo "missing schema file: $file" >&2; exit 1; }
  if [[ "$(table_count "$db")" == "0" ]]; then
    echo "==> import $(basename "$file") into ${db}"
    "${MYSQL[@]}" "$db" < "$file"
  else
    echo "==> ${db} already has tables; skip $(basename "$file")"
  fi
}

create_db_user "$PLATFORM_MANAGER_DB_NAME" "$PLATFORM_MANAGER_DB_USER" "$PLATFORM_MANAGER_DB_PASSWORD"
create_db_user "$PLATFORM_CONFIGURE_DB_NAME" "$PLATFORM_CONFIGURE_DB_USER" "$PLATFORM_CONFIGURE_DB_PASSWORD"
create_db_user "$PLATFORM_RESOURCE_DB_NAME" "$PLATFORM_RESOURCE_DB_USER" "$PLATFORM_RESOURCE_DB_PASSWORD"
create_db_user "$PLATFORM_GATEWAY_DB_NAME" "$PLATFORM_GATEWAY_DB_USER" "$PLATFORM_GATEWAY_DB_PASSWORD"

import_schema_if_empty "$PLATFORM_MANAGER_DB_NAME" "sql/manager_schema.sql"

seed_manager_app() {
  local db="$PLATFORM_MANAGER_DB_NAME" secret="${PLATFORM_MANAGER_JWT_SECRET:-}"
  [[ -n "$secret" ]] || { echo "PLATFORM_MANAGER_JWT_SECRET is required for a fresh manager DB" >&2; exit 1; }
  [[ "$secret" =~ ^[A-Za-z0-9_-]+$ ]] || { echo "PLATFORM_MANAGER_JWT_SECRET must be A-Z a-z 0-9 _ -" >&2; exit 1; }
  local tmp
  tmp="$(mktemp)"
  sed "s/__JWT_SECRET__/${secret}/g" sql/manager_seed.sql > "$tmp"
  echo "==> seed manager app and base app registry"
  "${MYSQL[@]}" "$db" < "$tmp"
  rm -f "$tmp"
}

if [[ "$(table_count "$PLATFORM_MANAGER_DB_NAME")" != "0" ]] \
  && [[ "$("${MYSQL[@]}" -N -B -e 'SELECT COUNT(*) FROM app' "$PLATFORM_MANAGER_DB_NAME")" == "0" ]]; then
  seed_manager_app
fi

import_schema_if_empty "$PLATFORM_CONFIGURE_DB_NAME" "sql/configure_schema.sql"
import_schema_if_empty "$PLATFORM_RESOURCE_DB_NAME" "sql/resource_schema.sql"

echo "==> apply gateway route seed"
"${MYSQL[@]}" "$PLATFORM_GATEWAY_DB_NAME" < sql/gateway_route_config.sql

echo "database initialization complete"
echo "PSou route migration 20261025_psou_client_route.sql was intentionally NOT applied"
