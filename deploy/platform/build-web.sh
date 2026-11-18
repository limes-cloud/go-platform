#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
CLIENT_SRC="${CLIENT_WEB_SRC:-$ROOT/web/psou}"
STAGE="${WEB_STAGE_DIR:-$HERE/.web-build}"
ADMIN_OUT="$STAGE/admin"
CLIENT_OUT="$STAGE/client"

# psou-web 的 JS/CSS（含动态 chunk）统一由 rustfs 机器（47）直出。
# vite base 设为 47 后，src/manifest.json 的 h5.router.base 必须保持 "/"，
# 这样 uni 运行时不会把 /static/... 本地图片也一起带到 47。
if [[ -f "$HERE/web-assets.env" ]]; then
  # shellcheck disable=SC1091
  source "$HERE/web-assets.env"
fi
CLIENT_ASSET_BASE="${PSOU_ASSET_BASE:-${WEB_ASSET_ORIGIN:+${WEB_ASSET_ORIGIN}/}}"
CLIENT_ASSET_BASE="${CLIENT_ASSET_BASE:-/}"

[[ -f "$CLIENT_SRC/package.json" ]] || { echo "client web source not found: $CLIENT_SRC" >&2; exit 1; }
[[ -x "$HERE/dist/web-server" ]] || { echo "missing dist/web-server; run ./build.sh first" >&2; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "pnpm is required to build web assets" >&2; exit 1; }

if [[ ! -d "$CLIENT_SRC/node_modules" ]]; then
  (cd "$CLIENT_SRC" && pnpm install --frozen-lockfile)
fi

rm -rf "$STAGE"
mkdir -p "$CLIENT_OUT" "$ADMIN_OUT"

(cd "$CLIENT_SRC" && VITE_ASSET_BASE="$CLIENT_ASSET_BASE" pnpm build:h5)
cp -R "$CLIENT_SRC/dist/build/h5/." "$CLIENT_OUT/"

ADMIN_WEB_OUT="$ADMIN_OUT" "$HERE/build-admin-web.sh"

rm -rf "$HERE/web"
mkdir -p "$HERE/web"
cp -R "$CLIENT_OUT/." "$HERE/web/client/"
cp -R "$ADMIN_OUT/." "$HERE/web/admin/"
cp "$HERE/web.Dockerfile" "$HERE/web/Dockerfile"
cp "$HERE/dist/web-server" "$HERE/web/web-server"
chmod 0755 "$HERE/web/web-server"

rm -rf "$STAGE"

echo "web docker context ready: $HERE/web"
