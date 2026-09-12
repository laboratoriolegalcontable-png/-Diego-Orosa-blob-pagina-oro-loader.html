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
#   - un usuario no-root en runtime,
#   - una unica ruta de datos (/data/knowledge-graph.jsonl) montada como volumen,
#     eliminando de raiz la clase de bug de rutas relativas/BASH_SOURCE.
#
# IMPORTANTE — persistencia: para que el contenedor lea/escriba el
# knowledge-graph.jsonl real de este repo (el que CLAUDE.md pide versionar
# en git), hay que montarlo con un bind mount explicito. Sin el `-v` de abajo,
# el contenedor usa un volumen anonimo vacio y la memoria existente no se
# carga ni se persiste al repo:
#
#   docker build -f .claude/docker/memory-mcp.Dockerfile -t oro-memory-mcp .
#   docker run -i --rm \
#     -v "$(pwd)/.claude/memory:/data" \
#     oro-memory-mcp
#
# (`$(pwd)` asume que se corre desde la raiz del repo — igual que el bug de
# rutas relativas que este Dockerfile busca evitar en el propio contenedor,
# el comando de host todavia depende del directorio de trabajo).
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

# su-exec: para poder arrancar como root (necesario para poder chown-ear un
# bind mount del host en runtime, ver entrypoint.sh) y despues bajar a un
# usuario sin privilegios antes de ejecutar el server MCP real.
RUN apk add --no-cache su-exec \
    && npm install -g "@modelcontextprotocol/server-memory@${MCP_MEMORY_VERSION}" \
    && npm cache clean --force

# El directorio de datos vive fuera de la imagen: se monta como volumen para
# que el knowledge-graph.jsonl persista entre reinicios del contenedor y
# pueda seguir versionandose en git desde el host.
ENV MEMORY_FILE_PATH=/data/knowledge-graph.jsonl
RUN mkdir -p /data && chown -R node:node /data
VOLUME ["/data"]

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

# El contenedor arranca como root (necesario para el chown en runtime del
# bind mount dentro de entrypoint.sh — el chown de build de arriba solo
# alcanza a volumenes anonimos/nombrados, no a `-v host:/data`, donde gana
# la ownership del host), pero entrypoint.sh nunca ejecuta el server MCP
# como root: baja a "node" via su-exec antes del exec final. Esto sigue
# mitigando el punto de "aislar servers MCP del host" que el reporte de
# Docker marca como uno de los 3 mayores desafios de seguridad — el proceso
# que efectivamente habla el protocolo MCP nunca corre con privilegios.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

