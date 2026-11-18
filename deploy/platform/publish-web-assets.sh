#!/usr/bin/env bash
# 把 admin-web / psou-web 的构建产物发布到 rustfs 机器（47）的 nginx 直出目录，
# 并把 Web 节点的 index.html 入口改成 ${WEB_ASSET_ORIGIN}/assets/... 绝对地址。
#
# 依赖：
#   - rs CLI（rs node list 里要有 rustfs 和 psou 两个节点）
#   - 先执行过 ./build-web.sh，产物在 deploy/platform/web/{admin,client}
#
# 用法：
#   ./publish-web-assets.sh admin
#   ./publish-web-assets.sh psou
#   ./publish-web-assets.sh all
#   ./publish-web-assets.sh all --no-restart   # 只发资源/改入口，不重启 Web 服务
#
# 注意：两个站点的 assets 合并到同一个目录，靠 content hash 文件名区分。
# 脚本会保存每个站点的 sha256 清单，合并后交叉校验；同名不同内容会直接失败。
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$HERE/web-assets.env"

[[ -f "$CONF" ]] || { echo "missing $CONF" >&2; exit 1; }
# shellcheck disable=SC1090
source "$CONF"

SITE="all"
RESTART=1
for arg in "$@"; do
  case "$arg" in
    admin|psou|all) SITE="$arg" ;;
    --no-restart) RESTART=0 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $arg" >&2; exit 1 ;;
  esac
done

: "${WEB_ASSET_ORIGIN:?}" "${WEB_ASSET_NODE:?}" "${WEB_ASSET_WEB_NODE:?}"
: "${WEB_ASSET_REMOTE_ROOT:?}" "${WEB_ASSET_REMOTE_MANIFEST_DIR:?}"

command -v rs >/dev/null 2>&1 || { echo "rs CLI not found" >&2; exit 1; }

die() { echo "error: $*" >&2; exit 1; }

SHA256_CMD=(sha256sum)
if command -v shasum >/dev/null 2>&1; then
  SHA256_CMD=(shasum -a 256)
fi

publish_assets() {
  local site="$1" src="$2"
  local tmp
  [[ -d "$src/assets" ]] || die "$site: $src/assets not found; run ./build-web.sh first"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/publish-web-assets.XXXXXX")"

  # 本地清单：路径写成 ./xxx，远端在 assets 根目录执行 sha256sum -c
  (cd "$src/assets" && find . -type f | LC_ALL=C sort | xargs "${SHA256_CMD[@]}") > "$tmp/$site.sha"

  local -a tar_opts=()
  if tar --no-xattrs -cf /dev/null --files-from /dev/null 2>/dev/null; then
    tar_opts+=(--no-xattrs)
  fi
  COPYFILE_DISABLE=1 tar "${tar_opts[@]}" -czf "$tmp/$site.tgz" -C "$src/assets" .

  rs push "$WEB_ASSET_NODE" "$tmp/$site.tgz" "/tmp/web-assets-$site.tgz" --overwrite >/dev/null
  rs push "$WEB_ASSET_NODE" "$tmp/$site.sha" "/tmp/web-assets-$site.sha" --overwrite >/dev/null

  cat > "$tmp/remote.sh" <<REMOTE
#!/usr/bin/env bash
set -euo pipefail
ROOT='${WEB_ASSET_REMOTE_ROOT}'
MANIFEST='${WEB_ASSET_REMOTE_MANIFEST_DIR}'
TS=\$(date +%Y%m%d%H%M%S)
mkdir -p "\$ROOT" "\$MANIFEST"
if [ -n "\$(ls -A "\$ROOT" 2>/dev/null || true)" ]; then
  BACKUP="\$(dirname "\$ROOT")/assets.backup.\$TS.tgz"
  tar -czf "\$BACKUP" -C "\$ROOT" .
  echo "backup: \$BACKUP"
fi
tar -xzf '/tmp/web-assets-$site.tgz' -C "\$ROOT"
cp '/tmp/web-assets-$site.sha' "\$MANIFEST/$site.sha"
OWNER=\$(stat -c '%u:%g' "\$ROOT")
chown -R "\$OWNER" "\$ROOT"
chmod -R a+rX "\$ROOT"
cd "\$ROOT"
fail=0
for f in "\$MANIFEST"/*.sha; do
  [ -e "\$f" ] || continue
  if ! sha256sum -c "\$f" >/dev/null 2>&1; then
    echo "asset conflict from: \$f" >&2
    sha256sum -c "\$f" 2>&1 | grep -v ': OK\$' >&2 || true
    fail=1
  fi
done
if [ "\$fail" -ne 0 ]; then
  echo "跨站点 assets 校验失败：存在同名不同内容的文件" >&2
  exit 1
fi
echo "$site assets ok: \$(find "\$ROOT" -type f | wc -l) files total"
REMOTE

  rs push "$WEB_ASSET_NODE" "$tmp/remote.sh" "/tmp/web-assets-$site.sh" --overwrite >/dev/null
  rs shell "$WEB_ASSET_NODE" "bash /tmp/web-assets-$site.sh" --timeout 300
  rm -rf "$tmp"
}

rewrite_index() {
  local site="$1" src="$2" web_dir="$3" service="$4" marker="$5"
  local tmp
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/rewrite-index.XXXXXX")"

  [[ -f "$src/index.html" ]] || die "$site: $src/index.html not found"
  rs push "$WEB_ASSET_WEB_NODE" "$src/index.html" "/tmp/web-index-$site.html" --overwrite >/dev/null

  cat > "$tmp/rewrite.sh" <<REMOTE
#!/usr/bin/env bash
set -euo pipefail
F='${web_dir}/index.html'
NEW='/tmp/web-index-${site}.html'
MARKER='${marker}'
ORIGIN='${WEB_ASSET_ORIGIN}'
SERVICE='${service}'
RESTART='${RESTART}'
[ -f "\$F" ] || { echo "missing \$F" >&2; exit 1; }
OWNER=\$(stat -c '%u:%g' "\$F")
MODE=\$(stat -c '%a' "\$F")
grep -qF "\$MARKER" "\$NEW" || { echo "new index missing marker \$MARKER" >&2; exit 1; }
cp -p "\$F" "\$F.bak.web-assets-\$(date +%Y%m%d%H%M%S)"
cat "\$NEW" > "\$F"
sed -i -E "s#((src|href)=\")/assets/#\\1\${ORIGIN}/assets/#g" "\$F"
chown "\$OWNER" "\$F"
chmod "\$MODE" "\$F"
echo "installed index: \$F"
if [ "\$RESTART" = "1" ]; then
  systemctl restart "\$SERVICE"
  sleep 1
  systemctl is-active "\$SERVICE"
else
  echo "skip restart: \$SERVICE"
fi
REMOTE

  rs push "$WEB_ASSET_WEB_NODE" "$tmp/rewrite.sh" "/tmp/rewrite-web-index-$site.sh" --overwrite >/dev/null
  rs shell "$WEB_ASSET_WEB_NODE" "bash /tmp/rewrite-web-index-$site.sh" --timeout 120
  rm -rf "$tmp"
}

smoke_check() {
  local site="$1" page="$2" asset
  asset="$(curl -fsS --max-time 20 "$page/" 2>/dev/null | grep -oE "${WEB_ASSET_ORIGIN}/assets/[^\"']+" | head -1 || true)"
  if [[ -z "$asset" ]]; then
    echo "warn: $site 首页未引用 $WEB_ASSET_ORIGIN/assets/，请检查 index.html" >&2
    return 0
  fi
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 20 "$asset" || true)"
  echo "$site smoke: $asset -> $code"
  [[ "$code" == "200" ]] || echo "warn: $site 入口资源返回 $code" >&2
}

publish_admin() {
  echo "==> publish admin-web assets"
  publish_assets admin "$HERE/web/admin"
  rewrite_index admin "$HERE/web/admin" "$ADMIN_WEB_REMOTE_DIR" "$ADMIN_WEB_SERVICE" '<!--__ADMIN_WEB_CONFIG__-->'
  smoke_check admin "${ADMIN_WEB_PUBLIC_URL:-}"
}

publish_psou() {
  echo "==> publish psou-web assets"
  publish_assets psou "$HERE/web/client"
  rewrite_index psou "$HERE/web/client" "$PSOU_WEB_REMOTE_DIR" "$PSOU_WEB_SERVICE" '<!--__PSOU_WEB_CONFIG__-->'
  smoke_check psou "${PSOU_WEB_PUBLIC_URL:-}"
}

case "$SITE" in
  admin) publish_admin ;;
  psou) publish_psou ;;
  all) publish_admin; publish_psou ;;
esac
