#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/dist}"
STAMP="$(date +%Y%m%d%H%M%S)"
ARCHIVE="$OUT_DIR/go-platform-deploy-$STAMP.tar.gz"

mkdir -p "$OUT_DIR"
"$HERE/build.sh"

tar -czf "$ARCHIVE" \
  --exclude='.env' \
  --exclude='.gocache' \
  --exclude='./.gocache' \
  --exclude='.gocache/*' \
  --exclude='./.gocache/*' \
  --exclude='runtime' \
  --exclude='./runtime' \
  --exclude='runtime/*' \
  --exclude='./runtime/*' \
  --exclude='*.tar.gz' \
  --exclude='*.sha256' \
  -C "$HERE" .

ARCHIVE_NAME="$(basename "$ARCHIVE")"
(
  cd "$OUT_DIR"
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
  else
    sha256sum "$ARCHIVE_NAME" > "$ARCHIVE_NAME.sha256"
  fi
)

echo "$ARCHIVE"
cat "$ARCHIVE.sha256"
