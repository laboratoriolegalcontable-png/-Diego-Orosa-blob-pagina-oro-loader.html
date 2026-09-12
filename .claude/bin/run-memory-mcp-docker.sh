#!/usr/bin/env bash
# Wrapper para el servidor MCP de memoria via Docker (entorno local/WSL).
#
# Hermano de run-memory-mcp.sh (que corre @modelcontextprotocol/server-memory
# directo con npx): esta version usa la imagen de
# .claude/docker/memory-mcp.Dockerfile en vez del paquete npm suelto, para
# entornos donde Docker esta disponible de forma persistente (WSL, Linux/Mac
# local) — ver informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md
# seccion 6. NO se usa por defecto en .mcp.json: el harness remoto de Claude
# Code on the web no garantiza un daemon de Docker disponible al arrancar la
# sesion, asi que .mcp.json sigue apuntando a run-memory-mcp.sh. Para usar
# esta version en una maquina local/WSL con Docker corriendo, cambiar el
# "args" de la entry "memory" en .mcp.json a
# [".claude/bin/run-memory-mcp-docker.sh"].
#
# Igual que run-memory-mcp.sh, resuelve su propia ubicacion en runtime via
# BASH_SOURCE en vez de asumir un cwd fijo (bug #1/#2 de MEMORY_FILE_PATH en
# CLAUDE.md) — asi funciona sin importar desde donde el harness invoque
# "bash <esta ruta>".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MEMORY_DIR="$SCRIPT_DIR/.claude/memory"
DOCKERFILE="$SCRIPT_DIR/.claude/docker/memory-mcp.Dockerfile"
IMAGE_TAG="oro-memory-mcp:local"
STAMP_FILE="$SCRIPT_DIR/.claude/docker/.image.stamp"

mkdir -p "$MEMORY_DIR"

# Rebuild solo si el Dockerfile cambio desde el ultimo build (evita
# reconstruir en cada arranque de sesion, que seria lento) o si la imagen
# todavia no existe.
CURRENT_HASH="$(sha256sum "$DOCKERFILE" | cut -d' ' -f1)"
NEEDS_BUILD=1
if docker image inspect "$IMAGE_TAG" >/dev/null 2>&1 \
  && [ -f "$STAMP_FILE" ] \
  && [ "$(cat "$STAMP_FILE")" = "$CURRENT_HASH" ]; then
  NEEDS_BUILD=0
fi

if [ "$NEEDS_BUILD" = "1" ]; then
  docker build -q -f "$DOCKERFILE" -t "$IMAGE_TAG" "$SCRIPT_DIR" >&2
  echo "$CURRENT_HASH" > "$STAMP_FILE"
fi

# --user "$(id -u):$(id -g)": el contenedor corre con el UID/GID de quien
# invoca este script, no con un usuario fijo de la imagen. Esto es
# deliberado (ver "POR QUE --user" en memory-mcp.Dockerfile, hallazgo real
# de cubic en PR #13): un entrypoint que hace chown del bind mount muta la
# ownership real de .claude/memory/ en el host, rompiendo run-memory-mcp.sh
# (el wrapper sin Docker) la proxima vez que se use sin --user. Pasando el
# UID/GID del host, el proceso dentro del contenedor tiene exactamente los
# mismos permisos que quien lo corrio — sin tocar la ownership de nada.
#
# -i (stdin interactivo, obligatorio para hablar MCP por stdio) sin -t (no es
# una TTY). --rm: no dejar contenedores muertos acumulandose entre sesiones.
exec docker run -i --rm \
  --user "$(id -u):$(id -g)" \
  -v "$MEMORY_DIR:/data" \
  "$IMAGE_TAG"
