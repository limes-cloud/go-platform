#!/bin/sh
set -eu

: "${APP_BINARY:?APP_BINARY is required}"
exec "/app/${APP_BINARY}"
