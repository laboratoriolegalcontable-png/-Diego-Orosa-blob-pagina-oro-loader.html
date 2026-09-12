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
#   - el proceso corre con el UID/GID del host (ver mas abajo — nunca root,
#     salvo que se invoque `docker run` como root en el host),
#   - una unica ruta de datos (/data/knowledge-graph.jsonl) montada como volumen,
#     eliminando de raiz la clase de bug de rutas relativas/BASH_SOURCE.
#
# USO RECOMENDADO — .claude/bin/run-memory-mcp-docker.sh: hace el build (solo
# si el Dockerfile cambio, cacheado por hash) y el `docker run` con el bind
# mount y el `--user` correctos, auto-resolviendo la ruta del repo igual que
# run-memory-mcp.sh. Probado de punta a punta contra la memoria real de este
# repo (ver CLAUDE.md, "Wrapper Docker para local/WSL"). Para usarlo desde
# Claude Code en una maquina local/WSL con Docker corriendo, cambiar en
# .mcp.json el `args` de la entry "memory" de `.claude/bin/run-memory-mcp.sh`
# a `.claude/bin/run-memory-mcp-docker.sh` (no es el default: el harness
# remoto de Claude Code on the web no garantiza un daemon de Docker
# disponible al arrancar la sesion).
#
# POR QUE `--user` Y NO chown-ear el bind mount (hallazgo real de `cubic` en
# PR #13): una version anterior de este Dockerfile arrancaba como root y
# hacia `chown -R node:node /data` en cada arranque para poder escribir el
# bind mount sin importar su ownership. Eso "arregla" el contenedor pero
# ROMPE el host: la primera vez que corre, muta el dueño real de
# `.claude/memory/` en el filesystem del host al UID fijo de la imagen
# (1000). Si el usuario del host no es UID 1000, `run-memory-mcp.sh` (el
# wrapper sin Docker, que corre con el UID real del usuario) deja de poder
# escribir `knowledge-graph.jsonl` — EACCES — la primera vez que se vuelve a
# usar sin Docker. La solucion correcta es la inversa: no tocar la ownership
# del bind mount nunca, y hacer que el CONTENEDOR corra con el UID/GID del
# host (`docker run --user "$(id -u):$(id -g)"`, lo hace el wrapper de
# arriba). Asi el proceso adentro del contenedor tiene exactamente los mismos
# permisos que el usuario que lo invoco — sin chown, sin mutacion, sin
# necesidad de arrancar como root ni de su-exec/gosu.
#
# IMPORTANTE — persistencia si se invoca `docker` a mano en vez del wrapper:
# para que el contenedor lea/escriba el knowledge-graph.jsonl real de este
# repo (el que CLAUDE.md pide versionar en git), hay que montarlo con un bind
# mount explicito Y pasar `--user` con el UID/GID de quien lo corre. Sin el
# `-v` de abajo, el contenedor usa un volumen anonimo vacio y la memoria
# existente no se carga ni se persiste al repo; sin el `--user`, el proceso
# corre como root dentro del contenedor (no aislado) o, si la imagen fijara
# un usuario propio, puede no coincidir con el dueño real del bind mount:
#
#   docker build -f .claude/docker/memory-mcp.Dockerfile -t oro-memory-mcp .
#   docker run -i --rm \
#     --user "$(id -u):$(id -g)" \
#     -v "$(pwd)/.claude/memory:/data" \
#     oro-memory-mcp
#
# (`$(pwd)` asume que se corre desde la raiz del repo — igual que el bug de
# rutas relativas que este Dockerfile busca evitar en el propio contenedor,
# el comando de host todavia depende del directorio de trabajo. Si se corre
# `docker` con `sudo`, `$(id -u):$(id -g)` da el UID de `sudo`, no el del
# usuario real — no anteponer `sudo` a este comando).
#
# El servidor habla MCP por stdio, asi que SIEMPRE se corre con `-i` (stdin
# interactivo) y sin `-t` (no es una TTY).
#
# Version pinneada: 2026.8.31 era la ultima publicada en el registry de npm
# al momento de escribir este Dockerfile (verificado contra
# https://registry.npmjs.org/@modelcontextprotocol/server-memory). Antes de
# actualizarla, revisar el changelog del paquete — no confiar en "latest".
FROM node:20-alpine AS base

ARG MCP_MEMORY_VERSION=2026.8.31

WORKDIR /app

RUN npm install -g "@modelcontextprotocol/server-memory@${MCP_MEMORY_VERSION}" \
    && npm cache clean --force

# El directorio de datos vive fuera de la imagen: se monta como volumen para
# que el knowledge-graph.jsonl persista entre reinicios del contenedor y
# pueda seguir versionandose en git desde el host. Permisos abiertos (rwx
# para todos + sticky bit, como /tmp) SOLO como fallback para el caso de uso
# no recomendado sin bind mount (volumen anonimo) — con `-v` + `--user`, la
# ownership real la define el bind mount del host, esto no se usa.
ENV MEMORY_FILE_PATH=/data/knowledge-graph.jsonl
RUN mkdir -p /data && chmod 1777 /data
VOLUME ["/data"]

# Sin USER fijo: quien invoca `docker run --user "$(id -u):$(id -g)"` decide
# con que UID/GID corre el proceso (ver nota "POR QUE --user" arriba). El
# binario del paquete npm queda con permisos de lectura/ejecucion para todos
# (default de `npm install -g`), asi que cualquier UID puede ejecutarlo.
ENTRYPOINT ["mcp-server-memory"]
