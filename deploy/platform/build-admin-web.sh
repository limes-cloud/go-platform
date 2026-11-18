#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SRC="${ADMIN_WEB_SRC:-$ROOT/web/admin-web}"
OUT="${ADMIN_WEB_OUT:-$HERE/web/admin}"

# 生产默认把静态资源放到 rustfs 机器（47）的 nginx 上直出，见 web-assets.env。
# VITE_BASE_URL 是 vite 的 base，会写进 index.html 和 chunk 引用；
# 同源部署时显式传 ADMIN_BASE_URL=/ 覆盖。
if [[ -f "$HERE/web-assets.env" ]]; then
  # shellcheck disable=SC1091
  source "$HERE/web-assets.env"
fi
ASSET_BASE="${ADMIN_BASE_URL:-${WEB_ASSET_ORIGIN:+${WEB_ASSET_ORIGIN}/}}"
ASSET_BASE="${ASSET_BASE:-/}"

[[ -f "$SRC/package.json" ]] || { echo "admin-web source not found: $SRC" >&2; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "pnpm is required to build admin-web" >&2; exit 1; }

if [[ ! -d "$SRC/node_modules" ]]; then
  (cd "$SRC" && pnpm install --frozen-lockfile)
fi

ENV_FILE="$SRC/.env.production.local"
BACKUP=""
if [[ -f "$ENV_FILE" ]]; then
  BACKUP="$(mktemp)"
  cp "$ENV_FILE" "$BACKUP"
fi
cleanup() {
  if [[ -n "$BACKUP" ]]; then
    mv "$BACKUP" "$ENV_FILE"
  else
    rm -f "$ENV_FILE"
  fi
}
trap cleanup EXIT

cat > "$ENV_FILE" <<EOF
VITE_BASE_URL = ${ASSET_BASE}
VITE_API_URL = ${ADMIN_API_URL:-}
EOF

# build 脚本包含 vue-tsc；部署构建使用 vite build，避免历史类型错误阻断发布。
(cd "$SRC" && pnpm exec vite build)

rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$SRC/dist/." "$OUT/"

echo "admin-web static ready: $OUT"
