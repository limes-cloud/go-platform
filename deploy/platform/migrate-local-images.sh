#!/usr/bin/env bash
set -euo pipefail

# Migrate local resource images to the remote MinIO deployment, then sync the
# object metadata and PSou category/resource rows.
#
# Defaults are for the current local -> psou environment. No secret is printed
# or passed as a command-line argument. Use --apply to make changes.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_ENV="${LOCAL_ENV:-$ROOT/server/psou/.env}"
LOCAL_RESOURCE_DB="${LOCAL_RESOURCE_DB:-resource}"
LOCAL_RESOURCE_APP="${LOCAL_RESOURCE_APP:-psou}"
LOCAL_PSOU_APP="${LOCAL_PSOU_APP:-psou_us}"
REMOTE_HOST="${REMOTE_HOST:-psou}"
REMOTE_STORE_KEYWORD="${REMOTE_STORE_KEYWORD:-minio}"
REMOTE_RESOURCE_APP="${REMOTE_RESOURCE_APP:-psou_us}"
WORK_DIR="${WORK_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/psou-image-migration}"
APPLY=0
RESTART=1
SKIP_DOWNLOAD=0

usage() {
  cat <<'EOF'
Usage: ./migrate-local-images.sh [options]

  --apply             Execute the remote migration. Without it, only inspect.
  --dry-run           Explicitly inspect only (the default).
  --work-dir DIR      Local cache directory for downloaded images.
  --remote-host NODE  rs node name (default: psou).
  --no-restart        Do not restart resource/PSou after the import.
  --skip-download     Reuse already verified images in --work-dir.
  -h, --help          Show this help.

Environment overrides:
  LOCAL_ENV             Local env file, default server/psou/.env
  LOCAL_RESOURCE_DB     Local resource database, default resource
  LOCAL_RESOURCE_APP    Local resource app key, default psou
  LOCAL_PSOU_APP        Local PSou app key, default psou_us
  REMOTE_STORE_KEYWORD  Remote resource.store keyword, default minio
  REMOTE_RESOURCE_APP   Remote PSou app key, default psou_us
EOF
}

log() { printf '[migrate] %s\n' "$*" >&2; }
die() { printf '[migrate] ERROR: %s\n' "$*" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --apply) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    --work-dir) WORK_DIR="${2:?missing value for --work-dir}"; shift ;;
    --remote-host) REMOTE_HOST="${2:?missing value for --remote-host}"; shift ;;
    --no-restart) RESTART=0 ;;
    --skip-download) SKIP_DOWNLOAD=1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

[[ -f "$LOCAL_ENV" ]] || die "local env not found: $LOCAL_ENV"
[[ "$LOCAL_PSOU_APP" == "$REMOTE_RESOURCE_APP" ]] || \
  die "LOCAL_PSOU_APP and REMOTE_RESOURCE_APP must match in this migration"
[[ "$REMOTE_STORE_KEYWORD" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$ ]] || \
  die "invalid REMOTE_STORE_KEYWORD"

for bin in mysql mysqldump curl tar rs; do
  command -v "$bin" >/dev/null 2>&1 || die "required command not found: $bin"
done
command -v shasum >/dev/null 2>&1 || command -v sha256sum >/dev/null 2>&1 || \
  die "required command not found: shasum or sha256sum"

set -a
# shellcheck disable=SC1090
source "$LOCAL_ENV"
set +a

: "${MYSQL_HOST:?MYSQL_HOST is missing}"
: "${MYSQL_PORT:?MYSQL_PORT is missing}"
: "${MYSQL_USER:?MYSQL_USER is missing}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is missing}"
: "${MYSQL_DB:?MYSQL_DB is missing}"

export LC_ALL=C

local_mysql=(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" --protocol=TCP --default-character-set=utf8mb4)
local_dump=(mysqldump -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" --protocol=TCP --default-character-set=utf8mb4 --single-transaction --quick --no-tablespaces --skip-triggers)

export MYSQL_PWD="$MYSQL_PASSWORD"
trap 'unset MYSQL_PWD' EXIT

"${local_mysql[@]}" -e 'SELECT 1' >/dev/null

STAMP="$(date +%Y%m%d%H%M%S)"
RUN_DIR="$WORK_DIR/$STAMP"
IMAGES_DIR="$WORK_DIR/images"
CHECKSUM_DIR="$WORK_DIR/checksums"
mkdir -p "$RUN_DIR" "$IMAGES_DIR" "$CHECKSUM_DIR"

SOURCE_MANIFEST="$RUN_DIR/sources.tsv"
UPLOAD_MANIFEST="$RUN_DIR/upload.tsv"

"${local_mysql[@]}" --batch --raw -N "$LOCAL_RESOURCE_DB" >"$SOURCE_MANIFEST" <<SQL
SELECT s.keyword, o.md5, LOWER(o.ext), o.size, s.public_base_url
FROM object o
JOIN store s ON s.keyword = o.store_keyword
WHERE LOWER(o.ext) IN ('jpg','jpeg','png','gif','webp','bmp','svg','ico','avif')
  AND o.md5 REGEXP '^[0-9a-fA-F]{32}$'
  AND o.size >= 0
  AND s.public_base_url <> ''
ORDER BY s.keyword, o.md5;
SQL

IMAGE_COUNT="$(wc -l <"$SOURCE_MANIFEST" | tr -d ' ')"
[[ "$IMAGE_COUNT" -gt 0 ]] || die "no image objects found"

mkdir -p "$RUN_DIR/sql"
{
  printf 'SET NAMES utf8mb4;\nSTART TRANSACTION;\n'
  "${local_mysql[@]}" --batch --raw -N "$LOCAL_RESOURCE_DB" <<SQL
SELECT CONCAT(
  'INSERT INTO \`object\` (\`store_keyword\`,\`md5\`,\`ext\`,\`size\`,\`created_at\`,\`updated_at\`) VALUES (',
  QUOTE('${REMOTE_STORE_KEYWORD}'), ',', QUOTE(md5), ',', QUOTE(LOWER(ext)), ',',
  size, ',', created_at, ',', updated_at,
  ') ON DUPLICATE KEY UPDATE \`ext\`=VALUES(\`ext\`),\`size\`=VALUES(\`size\`),\`updated_at\`=VALUES(\`updated_at\`);'
)
FROM object
WHERE LOWER(ext) IN ('jpg','jpeg','png','gif','webp','bmp','svg','ico','avif')
  AND md5 REGEXP '^[0-9a-fA-F]{32}$'
ORDER BY md5;
SQL
  "${local_mysql[@]}" --batch --raw -N "$LOCAL_RESOURCE_DB" <<SQL
SELECT CONCAT(
  'INSERT INTO \`app_config\` (\`app\`,\`store_keyword\`,\`export_store_keyword\`,\`default_accept\`,\`default_max_size\`,\`temp_url_ttl\`,\`export_ttl\`,\`quota\`,\`used_bytes\`,\`status\`,\`created_at\`,\`updated_at\`) VALUES (',
  QUOTE(IF(app='${LOCAL_RESOURCE_APP}','${REMOTE_RESOURCE_APP}',app)), ',',
  QUOTE('${REMOTE_STORE_KEYWORD}'), ',', QUOTE('${REMOTE_STORE_KEYWORD}'), ',',
  QUOTE(default_accept), ',', default_max_size, ',', temp_url_ttl, ',', export_ttl, ',',
  quota, ',', used_bytes, ',', status, ',', created_at, ',', updated_at,
  ') ON DUPLICATE KEY UPDATE \`store_keyword\`=VALUES(\`store_keyword\`),\`export_store_keyword\`=VALUES(\`export_store_keyword\`),\`default_accept\`=VALUES(\`default_accept\`),\`default_max_size\`=VALUES(\`default_max_size\`),\`temp_url_ttl\`=VALUES(\`temp_url_ttl\`),\`export_ttl\`=VALUES(\`export_ttl\`),\`quota\`=VALUES(\`quota\`),\`used_bytes\`=VALUES(\`used_bytes\`),\`status\`=VALUES(\`status\`),\`updated_at\`=VALUES(\`updated_at\`);'
)
FROM app_config
ORDER BY app;
SQL
  printf 'COMMIT;\n'
} >"$RUN_DIR/sql/resource.sql"

{
  printf 'SET NAMES utf8mb4;\nSTART TRANSACTION;\n'
  "${local_dump[@]}" --no-create-info --complete-insert --replace --skip-add-locks --skip-comments \
    --where="app = '${LOCAL_PSOU_APP}'" "$MYSQL_DB" category resource
  printf 'COMMIT;\n'
} >"$RUN_DIR/sql/psou.sql"

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

file_size() {
  if stat -f '%z' "$1" >/dev/null 2>&1; then
    stat -f '%z' "$1"
  else
    stat -c '%s' "$1"
  fi
}

: >"$UPLOAD_MANIFEST"
declare -A seen_keys=()
downloaded=0
reused=0
failed=0

while IFS=$'\t' read -r source_store md5 ext size base_url; do
  [[ -n "$source_store" && -n "$md5" && -n "$ext" ]] || continue
  key="${md5}.${ext}"
  if [[ -n "${seen_keys[$key]:-}" ]]; then
    continue
  fi
  seen_keys[$key]=1

  target="$IMAGES_DIR/$key"
  checksum_file="$CHECKSUM_DIR/$key.sha256"
  url="${base_url%/}/$key"

  if [[ "$SKIP_DOWNLOAD" != "1" ]]; then
    cached_ok=0
    if [[ -f "$target" && -f "$checksum_file" && "$(file_size "$target")" == "$size" ]]; then
      if [[ -n "$(cat "$checksum_file")" && "$(sha256_file "$target")" == "$(cat "$checksum_file")" ]]; then
        cached_ok=1
        reused=$((reused + 1))
      fi
    fi
    if [[ "$cached_ok" != "1" ]]; then
      tmp="$target.part"
      rm -f "$tmp"
      if ! curl -fsSL --retry 5 --retry-delay 2 --connect-timeout 15 --max-time 600 \
          -o "$tmp" "$url"; then
        rm -f "$tmp"
        printf 'download failed: %s\n' "$url" >&2
        failed=$((failed + 1))
        continue
      fi
      actual_size="$(file_size "$tmp")"
      if [[ "$actual_size" != "$size" ]]; then
        rm -f "$tmp"
        printf 'verification failed: %s size=%s/%s\n' "$url" "$actual_size" "$size" >&2
        failed=$((failed + 1))
        continue
      fi
      mv "$tmp" "$target"
      sha256_file "$target" >"$checksum_file"
      downloaded=$((downloaded + 1))
    fi
  elif [[ ! -f "$target" || ! -f "$checksum_file" ]]; then
    printf 'cached image/checksum missing: %s\n' "$target" >&2
    failed=$((failed + 1))
    continue
  fi

  [[ "$(file_size "$target")" == "$size" ]] || { printf 'size mismatch after cache: %s\n' "$target" >&2; failed=$((failed + 1)); continue; }
  [[ "$(sha256_file "$target")" == "$(cat "$checksum_file")" ]] || { printf 'sha256 mismatch after cache: %s\n' "$target" >&2; failed=$((failed + 1)); continue; }
  printf '%s\t%s\t%s\n' "$source_store" "$key" "$(sha256_file "$target")" >>"$UPLOAD_MANIFEST"
done <"$SOURCE_MANIFEST"

(( failed == 0 )) || die "$failed image(s) failed verification; fix them and rerun"

log "images=$IMAGE_COUNT unique=$(wc -l <"$UPLOAD_MANIFEST" | tr -d ' ') downloaded=$downloaded reused=$reused"
log "resource rows=$("${local_mysql[@]}" -N -B "$LOCAL_RESOURCE_DB" -e "SELECT COUNT(*) FROM object WHERE LOWER(ext) IN ('jpg','jpeg','png','gif','webp','bmp','svg','ico','avif')")"
log "psou category/resource rows=$("${local_mysql[@]}" -N -B "$MYSQL_DB" -e "SELECT (SELECT COUNT(*) FROM category WHERE app='${LOCAL_PSOU_APP}') + (SELECT COUNT(*) FROM resource WHERE app='${LOCAL_PSOU_APP}')")"

EXPECTED_IMAGES="$(wc -l <"$UPLOAD_MANIFEST" | tr -d ' ')"
EXPECTED_CATEGORIES="$("${local_mysql[@]}" -N -B "$MYSQL_DB" -e "SELECT COUNT(*) FROM category WHERE app='${LOCAL_PSOU_APP}'")"
EXPECTED_RESOURCES="$("${local_mysql[@]}" -N -B "$MYSQL_DB" -e "SELECT COUNT(*) FROM resource WHERE app='${LOCAL_PSOU_APP}'")"
cat >"$RUN_DIR/expected.env" <<EOF
EXPECTED_IMAGES='$EXPECTED_IMAGES'
EXPECTED_CATEGORIES='$EXPECTED_CATEGORIES'
EXPECTED_RESOURCES='$EXPECTED_RESOURCES'
EOF

if [[ "$APPLY" != "1" ]]; then
  log "dry-run complete; rerun with --apply to upload and import"
  log "prepared: $RUN_DIR"
  exit 0
fi

cat >"$RUN_DIR/apply.sh" <<'REMOTE'
#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?bundle root is required}"
STAMP="${2:?stamp is required}"
REMOTE_STORE_KEYWORD="${3:?store keyword is required}"
RESTART="${4:-1}"

MINIO_BASE=/www/software/minio
PLATFORM_BASE=/www/software/go-platform
PSOU_BASE=/www/software/go-platform/psou

set -a
# shellcheck disable=SC1090
source "$MINIO_BASE/.env"
# shellcheck disable=SC1090
source "$PLATFORM_BASE/.env"
# shellcheck disable=SC1090
source "$PSOU_BASE/.env"
set +a

# shellcheck disable=SC1091
source "$ROOT/expected.env"

MYSQL_BIN="${PLATFORM_MYSQL_BIN:-mysql}"
MYSQLDUMP_BIN="${PLATFORM_MYSQLDUMP_BIN:-mysqldump}"
MC="$MINIO_BASE/bin/mc"
[[ -x "$MC" ]] || { echo "mc not found: $MC" >&2; exit 1; }

mysql_resource=("$MYSQL_BIN" -h "${PLATFORM_DB_HOST:-127.0.0.1}" -P "${PLATFORM_DB_PORT:-3306}" -u "$PLATFORM_RESOURCE_DB_USER" --protocol=TCP --default-character-set=utf8mb4)
mysql_psou=("$MYSQL_BIN" -h "${MYSQL_HOST:-127.0.0.1}" -P "${MYSQL_PORT:-3306}" -u "$MYSQL_USER" --protocol=TCP --default-character-set=utf8mb4)

STORE_ROW="$(MYSQL_PWD="$PLATFORM_RESOURCE_DB_PASSWORD" "${mysql_resource[@]}" -N -B "$PLATFORM_RESOURCE_DB_NAME" -e "SELECT CONCAT_WS('|',provider,endpoint,bucket,status) FROM store WHERE keyword='${REMOTE_STORE_KEYWORD}'")"
IFS='|' read -r STORE_PROVIDER STORE_ENDPOINT STORE_BUCKET STORE_STATUS <<<"$STORE_ROW"
[[ "$STORE_PROVIDER" == "minio" && "$STORE_BUCKET" == "$MINIO_BUCKET" && "$STORE_STATUS" == "1" ]] || {
  echo "remote store mismatch: $REMOTE_STORE_KEYWORD provider=$STORE_PROVIDER bucket=$STORE_BUCKET" >&2
  exit 1
}

BACKUP_DIR="$PLATFORM_BASE/backups/psou-image-migration-$STAMP"
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

MYSQL_PWD="$PLATFORM_RESOURCE_DB_PASSWORD" "$MYSQLDUMP_BIN" \
  -h "${PLATFORM_DB_HOST:-127.0.0.1}" -P "${PLATFORM_DB_PORT:-3306}" \
  -u "$PLATFORM_RESOURCE_DB_USER" --protocol=TCP --single-transaction --quick --no-tablespaces \
  "$PLATFORM_RESOURCE_DB_NAME" object app_config >"$BACKUP_DIR/resource-object-app_config.sql"
MYSQL_PWD="$MYSQL_PASSWORD" "$MYSQLDUMP_BIN" \
  -h "${MYSQL_HOST:-127.0.0.1}" -P "${MYSQL_PORT:-3306}" \
  -u "$MYSQL_USER" --protocol=TCP --single-transaction --quick --no-tablespaces \
  "$MYSQL_DB" category resource >"$BACKUP_DIR/psou-category-resource.sql"
chmod 600 "$BACKUP_DIR"/*.sql

export MC_CONFIG_DIR="$ROOT/.mc"
mkdir -p "$MC_CONFIG_DIR"
export MC_HOST_migration="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@${MINIO_API_BIND}:${MINIO_API_PORT}"

"$MC" cp --recursive --quiet "$ROOT/images/" "migration/${MINIO_BUCKET}/"

verified=0
while IFS=$'\t' read -r source_store key expected_sha; do
  [[ -n "$key" ]] || continue
  actual_sha="$("$MC" cat "migration/${MINIO_BUCKET}/${key}" | sha256sum | awk '{print $1}')"
  if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "minio verification failed: $key" >&2
    exit 1
  fi
  verified=$((verified + 1))
done <"$ROOT/upload.tsv"
[[ "$verified" == "$EXPECTED_IMAGES" ]] || { echo "verified count mismatch: $verified/$EXPECTED_IMAGES" >&2; exit 1; }

MYSQL_PWD="$PLATFORM_RESOURCE_DB_PASSWORD" "${mysql_resource[@]}" "$PLATFORM_RESOURCE_DB_NAME" <"$ROOT/sql/resource.sql"
MYSQL_PWD="$MYSQL_PASSWORD" "${mysql_psou[@]}" "$MYSQL_DB" <"$ROOT/sql/psou.sql"

md5_sql=""
while IFS=$'\t' read -r source_store key expected_sha; do
  [[ -n "$key" ]] || continue
  md5_value="${key%%.*}"
  md5_sql="${md5_sql:+$md5_sql,}'$md5_value'"
done <"$ROOT/upload.tsv"
RESOURCE_COUNT="$(MYSQL_PWD="$PLATFORM_RESOURCE_DB_PASSWORD" "${mysql_resource[@]}" -N -B "$PLATFORM_RESOURCE_DB_NAME" -e "SELECT COUNT(*) FROM object WHERE store_keyword='${REMOTE_STORE_KEYWORD}' AND md5 IN ($md5_sql)")"
[[ "$RESOURCE_COUNT" == "$EXPECTED_IMAGES" ]] || { echo "resource object count mismatch: $RESOURCE_COUNT/$EXPECTED_IMAGES" >&2; exit 1; }
PSOU_COUNT="$(MYSQL_PWD="$MYSQL_PASSWORD" "${mysql_psou[@]}" -N -B "$MYSQL_DB" -e "SELECT CONCAT((SELECT COUNT(*) FROM category),( '|' ),(SELECT COUNT(*) FROM resource))")"
PSOU_CATEGORIES="${PSOU_COUNT%%|*}"
PSOU_RESOURCES="${PSOU_COUNT##*|}"
(( PSOU_CATEGORIES >= EXPECTED_CATEGORIES )) || { echo "category count mismatch: $PSOU_CATEGORIES/$EXPECTED_CATEGORIES" >&2; exit 1; }
(( PSOU_RESOURCES >= EXPECTED_RESOURCES )) || { echo "resource count mismatch: $PSOU_RESOURCES/$EXPECTED_RESOURCES" >&2; exit 1; }

if [[ "$RESTART" == "1" ]]; then
  docker restart platform-resource >/dev/null 2>&1 || true
  for _ in $(seq 1 90); do
    health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' platform-resource 2>/dev/null || true)"
    [[ "$health" == "healthy" || "$health" == "running" ]] && break
    sleep 1
  done
  [[ "${health:-}" == "healthy" || "${health:-}" == "running" ]] || {
    echo "platform-resource did not become healthy" >&2
    exit 1
  }
  systemctl restart go-platform-psou.service
  systemctl is-active --quiet go-platform-psou.service || {
    echo "go-platform-psou.service is not active" >&2
    exit 1
  }
fi

printf 'images_verified=%s\n' "$verified"
printf 'resource_objects=%s\n' "$RESOURCE_COUNT"
printf 'psou_category_resource=%s\n' "$PSOU_COUNT"
printf 'backup=%s\n' "$BACKUP_DIR"
REMOTE
chmod +x "$RUN_DIR/apply.sh"

BUNDLE="$RUN_DIR/bundle.tar.gz"
TAR_XATTR_OPTS=()
if tar --no-xattrs -cf /dev/null --files-from /dev/null 2>/dev/null; then
  TAR_XATTR_OPTS+=(--no-xattrs)
fi
DISABLE_COPYFILE=1 COPYFILE_DISABLE=1 tar "${TAR_XATTR_OPTS[@]}" -czf "$BUNDLE" \
  -C "$WORK_DIR" images \
  -C "$RUN_DIR" sql sources.tsv upload.tsv expected.env apply.sh
BUNDLE_SHA="$(sha256_file "$BUNDLE")"
REMOTE_DIR="/tmp/psou-image-migration-$STAMP"

log "uploading bundle=$BUNDLE"
rs shell "$REMOTE_HOST" "mkdir -p '$REMOTE_DIR' && rm -rf '$REMOTE_DIR'/*" --timeout 30 >/dev/null
rs push "$REMOTE_HOST" "$BUNDLE" "$REMOTE_DIR/bundle.tar.gz" --overwrite >/dev/null
rs shell "$REMOTE_HOST" "printf '%s  %s\\n' '$BUNDLE_SHA' '$REMOTE_DIR/bundle.tar.gz' | sha256sum -c - && tar -xzf '$REMOTE_DIR/bundle.tar.gz' -C '$REMOTE_DIR'" --timeout 120 >/dev/null

log "applying on $REMOTE_HOST"
rs shell "$REMOTE_HOST" "bash '$REMOTE_DIR/apply.sh' '$REMOTE_DIR' '$STAMP' '$REMOTE_STORE_KEYWORD' '$RESTART'" --timeout 900

log "completed; local cache: $WORK_DIR; remote staging: $REMOTE_DIR"
