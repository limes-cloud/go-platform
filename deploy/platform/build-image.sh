#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE="${1:?usage: $0 <manager|configure|resource|gateway|cron|ai-agent> [image-tag]}"
TAG="${2:-go-platform-${SERVICE}:local}"

case "$SERVICE" in
  configure)
    WORKDIR=/app
    ASSETS=configure
    ;;
  manager|resource|gateway)
    WORKDIR=/go/build
    ASSETS="$SERVICE"
    ;;
  cron|ai-agent)
    WORKDIR=/go/build
    ASSETS=""
    ;;
  *)
    echo "unsupported service: $SERVICE" >&2
    exit 1
    ;;
esac

[[ -f "$HERE/dist/$SERVICE" ]] || {
  echo "missing dist/$SERVICE; run ./build.sh first" >&2
  exit 1
}

docker build \
  --build-arg "BINARY=$SERVICE" \
  --build-arg "APP_DIR=$ASSETS" \
  --build-arg "APP_WORKDIR=$WORKDIR" \
  -t "$TAG" \
  "$HERE"
