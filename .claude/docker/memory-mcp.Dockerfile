# Imagen del servidor MCP de memoria persistente (`@modelcontextprotocol/server-memory`)
# usado por este repo via `.claude/bin/run-memory-mcp.sh` (entry "memory" en .mcp.json).
#
# Por que existe: los 3 bugs de MEMORY_FILE_PATH documentados en CLAUDE.md (y el
# analisis de "The State of Agentic AI", Docker 2026, en
# informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md) son sintoma
# de correr un MCP server directamente sobre el host, sin el aislamiento y la
# reproducibilidad que da un contenedor. Esta imagen fija:
#   - la version exacta del paquete npm (evita "rug pulls" de una dependencia que
#     cambia de contenido sin aviso — riesgo que el reporte de Docker marca como
#     una de las 3 amenazas top de seguridad en MCP: prompt injection, tool
#     poisoning, rug pulls),
#   - un usuario no-root,
#   - una unica ruta de datos (/data/knowledge-graph.jsonl) montada como volumen,
#     eliminando de raiz la clase de bug de rutas relativas/BASH_SOURCE.
#
# Uso (entorno local/WSL — ver informes/2026-08-22-arquitectura-memoria-distribuida-wsl.md
# para si esto reemplaza o convive con ese setup):
#
#   docker build -f .claude/docker/memory-mcp.Dockerfile -t oro-memory-mcp .
#   docker run -i --rm \
#     -v "$(pwd)/.claude/memory:/data" \
#     oro-memory-mcp
#
# El servidor habla MCP por stdio, asi que SIEMPRE se corre con `-i` (stdin
# interactivo) y sin `-t` (no es una TTY). Para usarlo desde Claude Code,
# .mcp.json apuntaria a un wrapper que invoque el `docker run` de arriba en vez
# de `bash .claude/bin/run-memory-mcp.sh` directo — ver nota en CLAUDE.md.
#
# Version pinneada: 2026.8.31 era la ultima publicada en el registry de npm
# al momento de escribir este Dockerfile (verificado contra
# https://registry.npmjs.org/@modelcontextprotocol/server-memory). Antes de
# actualizarla, revisar el changelog del paquete — no confiar en "latest".
FROM node:20-alpine AS base

ARG MCP_MEMORY_VERSION=2026.8.31

WORKDIR /app

# Instala el paquete de forma fija en tiempo de build (no via `npx -y` en cada
# arranque): reproducible, no depende de red en runtime, y evita que una
# version nueva y no auditada del paquete se instale sola en produccion.
RUN npm install -g "@modelcontextprotocol/server-memory@${MCP_MEMORY_VERSION}" \
    && npm cache clean --force

# El directorio de datos vive fuera de la imagen: se monta como volumen para
# que el knowledge-graph.jsonl persista entre reinicios del contenedor y
# pueda seguir versionandose en git desde el host.
ENV MEMORY_FILE_PATH=/data/knowledge-graph.jsonl
RUN mkdir -p /data && chown -R node:node /data
VOLUME ["/data"]

# Correr como usuario sin privilegios (la imagen node:*-alpine ya trae el
# usuario "node") — mitiga el punto de "aislar servers MCP del host" que el
# reporte de Docker marca como uno de los 3 mayores desafios de seguridad.
USER node

ENTRYPOINT ["mcp-server-memory"]

