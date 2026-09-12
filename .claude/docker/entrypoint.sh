#!/bin/sh
# Arranca como root (necesario para poder chown-ear un bind mount del host,
# cuya ownership pisa lo que el Dockerfile haya hecho en build time — ver
# hallazgo de cubic en PR #12: chown en build solo sirve para volumenes
# anonimos/nombrados, no para `-v host:/data`), corrige el dueño de /data y
# recien ahi baja privilegios a "node" antes de ejecutar el server MCP real.
set -eu

DATA_DIR="$(dirname "$MEMORY_FILE_PATH")"
mkdir -p "$DATA_DIR"
chown -R node:node "$DATA_DIR"

exec su-exec node mcp-server-memory
