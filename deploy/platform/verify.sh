#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

FAIL=0
ok() { echo "[ok]   $*"; }
bad() { echo "[fail] $*" >&2; FAIL=1; }

for container in platform-manager platform-configure platform-resource platform-gateway platform-cron platform-ai-agent platform-web platform-admin-web; do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || echo missing)"
  if [[ "$status" == "healthy" || "$status" == "running" ]]; then
    ok "container ${container}: ${status}"
  else
    bad "container ${container}: ${status}"
  fi
done

http_check() {
  local name="$1" url="$2" expect="$3"
  shift 3
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$@" "$url" 2>/dev/null || true)"
  if [[ "$code" == "$expect" ]]; then
    ok "${name}: HTTP ${code}"
  else
    bad "${name}: HTTP ${code:-000} (expected ${expect})"
  fi
}

http_any_check() {
  local name="$1" url="$2" code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || true)"
  if [[ "$code" =~ ^[234][0-9][0-9]$ ]]; then
    ok "${name}: HTTP ${code}"
  else
    bad "${name}: HTTP ${code:-000}"
  fi
}

http_auth_check() {
  local name="$1" url="$2" code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || true)"
  if [[ "$code" == "401" || "$code" == "403" ]]; then
    ok "${name}: HTTP ${code}"
  else
    bad "${name}: HTTP ${code:-000} (expected 401 or 403)"
  fi
}

http_check "gateway health" "http://127.0.0.1:7200/gateway/api/health" "200"
http_check "manager gateway route" "http://127.0.0.1:7200/manager/api/system/setting" "200"
http_check "manager setting" "http://127.0.0.1:7202/manager/api/system/setting" "200"
http_check "web client index" "http://127.0.0.1:7402/" "200"
http_check "web client spa fallback" "http://127.0.0.1:7402/psou/account" "200"
http_check "web client missing asset" "http://127.0.0.1:7402/assets/__missing__.js" "404"
SEO_OK=0
for seo_host in poposo.cc asou.fun; do
  if curl -fsS --max-time 5 -H "Host: ${seo_host}" -H 'User-Agent: Baiduspider' http://127.0.0.1:7202/manager/seo 2>/dev/null | grep -q '<title>'; then
    SEO_OK=1
    break
  fi
done
if [[ "$SEO_OK" -eq 1 ]]; then
  ok "manager seo home"
else
  bad "manager seo home missing"
fi
SEO_GATEWAY_OK=0
for seo_host in poposo.cc asou.fun; do
  if curl -fsS --max-time 5 -H "Host: ${seo_host}" -H 'User-Agent: Baiduspider' http://127.0.0.1:7200/ 2>/dev/null | grep -q '<title>'; then
    SEO_GATEWAY_OK=1
    break
  fi
done
if [[ "$SEO_GATEWAY_OK" -eq 1 ]]; then
  ok "gateway spider seo rewrite"
else
  bad "gateway spider seo rewrite missing"
fi
if curl -fsS --max-time 5 -H 'Host: asou.fun' -H 'User-Agent: Mozilla/5.0' http://127.0.0.1:7200/ 2>/dev/null | grep -q 'window.__PSOU_WEB_CONFIG__='; then
  ok "gateway normal user spa rewrite"
else
  bad "gateway normal user spa rewrite missing"
fi
if curl -fsS --max-time 5 http://127.0.0.1:7402/index.html 2>/dev/null | grep -q 'window.__PSOU_WEB_CONFIG__='; then
  ok "web client runtime config injected"
else
  bad "web client runtime config missing"
fi
http_check "admin web index" "http://127.0.0.1:7401/" "200"
http_check "admin web spa fallback" "http://127.0.0.1:7401/apps/resource/store" "200"
http_check "admin web missing asset" "http://127.0.0.1:7401/assets/__missing__.js" "404"
if curl -fsS --max-time 5 http://127.0.0.1:7401/ 2>/dev/null | grep -q 'window.__ADMIN_WEB_CONFIG__='; then
  ok "web admin runtime config injected"
else
  bad "web admin runtime config missing"
fi
http_any_check "configure listener" "http://127.0.0.1:7201/"
http_any_check "resource listener" "http://127.0.0.1:7203/"
http_any_check "cron listener" "http://127.0.0.1:7204/"
http_any_check "ai-agent listener" "http://127.0.0.1:7206/"
http_auth_check "cron gateway auth" "http://127.0.0.1:7200/cron/api/v1/task_groups"
http_auth_check "ai-agent gateway auth" "http://127.0.0.1:7200/ai-agent/api/models"

if command -v ss >/dev/null 2>&1; then
  LISTEN="$(ss -lnt 2>/dev/null || true)"
elif command -v netstat >/dev/null 2>&1; then
  LISTEN="$(netstat -lnt 2>/dev/null || true)"
else
  LISTEN=""
fi

if [[ -n "$LISTEN" ]]; then
  for port in 7200 7201 8201 7202 8202 7203 8203 7204 8204 7206 8206 7401 7402; do
    if grep -Eq "[:.]${port}([[:space:]]|$)" <<<"$LISTEN"; then
      ok "port ${port} listening"
    else
      bad "port ${port} not listening"
    fi
  done
fi

if systemctl list-unit-files 2>/dev/null | grep -q '^psou.service'; then
  if systemctl is-active --quiet psou.service; then
    ok "existing psou.service is active"
  else
    bad "existing psou.service is not active"
  fi
  if [[ -n "$LISTEN" ]] && grep -Eq '[:.]7010([[:space:]]|$)' <<<"$LISTEN"; then
    ok "existing psou port 7010 listening"
  else
    bad "existing psou port 7010 not listening"
  fi
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "verification failed" >&2
  exit 1
fi

echo "verification passed"
