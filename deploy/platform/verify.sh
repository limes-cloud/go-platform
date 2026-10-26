#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE"

FAIL=0
ok() { echo "[ok]   $*"; }
bad() { echo "[fail] $*" >&2; FAIL=1; }

for container in platform-manager platform-configure platform-resource platform-gateway; do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container" 2>/dev/null || echo missing)"
  if [[ "$status" == "healthy" || "$status" == "running" ]]; then
    ok "container ${container}: ${status}"
  else
    bad "container ${container}: ${status}"
  fi
done

http_check() {
  local name="$1" url="$2" expect="$3"
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || true)"
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

http_check "gateway health" "http://127.0.0.1:7200/gateway/api/health" "200"
http_check "manager setting" "http://127.0.0.1:7202/manager/api/system/setting" "200"
http_any_check "configure listener" "http://127.0.0.1:7201/"
http_any_check "resource listener" "http://127.0.0.1:7203/"

if command -v ss >/dev/null 2>&1; then
  LISTEN="$(ss -lnt 2>/dev/null || true)"
elif command -v netstat >/dev/null 2>&1; then
  LISTEN="$(netstat -lnt 2>/dev/null || true)"
else
  LISTEN=""
fi

if [[ -n "$LISTEN" ]]; then
  for port in 7200 7201 8201 7202 8202 7203 8203; do
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
