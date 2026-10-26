#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
TARGET_OS="${TARGET_OS:-linux}"
TARGET_ARCH="${TARGET_ARCH:-amd64}"

find_go() {
  local candidate version
  local -a candidates=()
  [[ -n "${GO_BIN:-}" ]] && candidates+=("$GO_BIN")
  candidates+=("$(command -v go 2>/dev/null || true)")
  candidates+=("$(command -v go1.26.3 2>/dev/null || true)")
  candidates+=("$HOME/.gvm/gos/go1.26.3/bin/go")
  candidates+=("/usr/local/go/bin/go")

  for candidate in "${candidates[@]}"; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    version="$("$candidate" env GOVERSION 2>/dev/null || true)"
    if [[ "$version" =~ ^go1\.([0-9]+) ]] && (( BASH_REMATCH[1] >= 26 )); then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

GO_BIN="$(find_go)" || {
  echo "Go 1.26+ is required; set GO_BIN=/path/to/go1.26/bin/go" >&2
  exit 1
}
export GOCACHE="${GOCACHE:-$HERE/.gocache}"
mkdir -p "$GOCACHE"

echo "==> using $("$GO_BIN" env GOVERSION) at $GO_BIN"

rm -rf "$HERE/dist" "$HERE/assets" "$HERE/conf"
mkdir -p "$HERE/dist" "$HERE/conf"

for name in configure manager resource gateway; do
  echo "==> build ${name} (${TARGET_OS}/${TARGET_ARCH})"
  (
    cd "$ROOT/server/$name"
    GOTOOLCHAIN=local CGO_ENABLED=0 GOOS="$TARGET_OS" GOARCH="$TARGET_ARCH" \
      "$GO_BIN" build -trimpath -ldflags="-s -w" -o "$HERE/dist/$name" .
  )
done

mkdir -p \
  "$HERE/assets/configure" \
  "$HERE/assets/manager" \
  "$HERE/assets/resource" \
  "$HERE/assets/gateway"

cp -R "$ROOT/server/configure/deploy" "$HERE/assets/configure/"
cp -R "$ROOT/server/manager/static" "$HERE/assets/manager/"
cp -R "$ROOT/server/resource/static" "$HERE/assets/resource/"
cp -R "$ROOT/server/gateway/deploy" "$HERE/assets/gateway/"

install -m 0644 "$ROOT/server/configure/conf/conf.yaml" "$HERE/conf/configure.yaml"
install -m 0644 "$ROOT/server/manager/conf/conf.yaml" "$HERE/conf/manager.yaml"
install -m 0644 "$ROOT/server/resource/conf/conf.yaml" "$HERE/conf/resource.yaml"
install -m 0644 "$ROOT/server/gateway/config/config.yaml" "$HERE/conf/gateway.yaml"

echo "==> build complete"
du -sh "$HERE/dist" "$HERE/assets"
