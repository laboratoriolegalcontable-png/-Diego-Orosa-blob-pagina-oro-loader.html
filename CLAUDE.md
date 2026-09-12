# CLAUDE.md

## Memoria persistente (MCP)

Este repo tiene instalado el servidor MCP oficial `@modelcontextprotocol/server-memory`
(entry `"memory"` en `.mcp.json`), un knowledge graph persistente (entidades/relaciones/
observaciones) para que Claude recuerde contexto entre sesiones.

- Storage: `.claude/memory/knowledge-graph.jsonl` (versionado en git, no en `/tmp`, para
  que sobreviva a reinicios del entorno).
- Usar `create_entities` / `create_relations` / `add_observations` para guardar contexto
  nuevo; `search_nodes` / `read_graph` antes de asumir que no hay contexto previo.
- Despues de escribir memoria nueva: `git add .claude/memory/` + commit, o se pierde al
  reciclar el contenedor.
- Para replicar en otro repo: copiar el bloque `"memory": {...}` a su `.mcp.json` y crear
  un `.claude/memory/knowledge-graph.jsonl` vacio.

**BUG CONFIRMADO (2026-07-21):** `${CLAUDE_PROJECT_DIR}` en `env.MEMORY_FILE_PATH`
NO se expande en este harness para servidores MCP tipo `command`/stdio (ENOENT
resolviendo contra la carpeta del paquete npm, no el repo). Se reemplazo por
ruta absoluta hardcodeada.

**BUG #2 CONFIRMADO Y CORREGIDO (2026-08-20):** la ruta absoluta hardcodeada
original (`/home/user/pagina-oro-loader/.claude/memory/knowledge-graph.jsonl`)
NO coincidia con el working directory real de este entorno
(`/home/user/-Diego-Orosa-blob-pagina-oro-loader.html`). Esa carpeta no existe,
asi que el servidor de memoria nunca pudo escribir nada — el archivo real
(`knowledge-graph.jsonl` en este repo) quedo vacio (0 lineas) todo este tiempo.
Se corrigio `MEMORY_FILE_PATH` en `.mcp.json` para que apunte a la ruta real:
`/home/user/-Diego-Orosa-blob-pagina-oro-loader.html/.claude/memory/knowledge-graph.jsonl`.
Si el entorno vuelve a montar el repo en otra carpeta, volver a verificar esta
ruta antes de confiar en la persistencia.

**FIX #3 — ruta ya no hardcodeada (2026-08-21):** por sugerencia del bot de
revision `cubic` en el PR #4, `.mcp.json` ya no fija `MEMORY_FILE_PATH` a una
ruta absoluta. Ahora `"memory"` corre via `.claude/bin/run-memory-mcp.sh`, que
resuelve su propia ubicacion en runtime (`BASH_SOURCE`) y arma la ruta a
partir de ahi. Si el harness vuelve a montar el repo en otra carpeta, esto
deberia seguir funcionando sin tocar nada — pero si `.mcp.json` vuelve a fallar,
revisar primero que el `command`/`args` sigan apuntando al wrapper (a veces un
entorno headless resuelve `args` relativos contra un cwd distinto al root del
repo; en ese caso, usar una ruta absoluta explicita en `args` como fallback).

**Contexto de industria (2026-09-11):** los 3 bugs de `MEMORY_FILE_PATH` de
arriba no son un caso aislado — son el mismo patron que describe el reporte
"The State of Agentic AI" de Docker (2026): MCP se adopta rapido pero la
mayoria de los equipos opera "en modo salto de fe" (85% conoce MCP, pero 42%
sufre sobrecarga operativa y 41% problemas de instalacion/configuracion). Ver
analisis completo y recomendaciones aplicadas a NARAKIA/Estudio Oro en
`informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md`.

**Dockerfile del memory-mcp (2026-09-12):** `.claude/docker/memory-mcp.Dockerfile`
contenedoriza el server de memoria (version de npm pinneada,
`/data/knowledge-graph.jsonl` como volumen) — build y smoke test (handshake
MCP `initialize`) validados localmente. `.mcp.json` sigue usando
`run-memory-mcp.sh` sin cambios: esta imagen es una alternativa para
entornos que la soporten (local/WSL), no un reemplazo automatico, porque
falta confirmar si el harness de Claude Code on the web permite correr un
MCP `command` que a su vez invoque `docker run` dentro de esta sesion remota.

**Ownership del bind mount — 2 rondas de fixes (2026-09-12):** la primera
version del Dockerfile arrancaba como root, hacia `chown -R node:node /data`
en cada arranque, y bajaba privilegios via `su-exec` — esto "arreglaba" el
contenedor pero **mutaba permanentemente** la ownership real de
`.claude/memory/` en el host al UID fijo de la imagen (hallazgo real de
`cubic` en PR #13), rompiendo `run-memory-mcp.sh` (el wrapper sin Docker) la
proxima vez que se usara sin `--user`. Fix definitivo: se elimino
`entrypoint.sh` entero; el contenedor no fija usuario propio, y quien lo
corre pasa `docker run --user "$(id -u):$(id -g)"` (lo hace
`run-memory-mcp-docker.sh` automaticamente) — el proceso corre con los
mismos permisos que el usuario del host, sin tocar la ownership de nada.
Validado con un UID de host arbitrario (2500, ni root ni el 1000 original):
lectura/escritura sin `EACCES`, ownership del host verificada igual antes y
despues.

**Wrapper Docker para local/WSL (2026-09-12):** `.claude/bin/run-memory-mcp-docker.sh`
es el equivalente a `run-memory-mcp.sh` pero corriendo la imagen del punto
anterior en vez de `npx` directo. Auto-resuelve su ubicacion (mismo patron
`BASH_SOURCE` que `run-memory-mcp.sh`), rebuildea la imagen solo si el
Dockerfile cambio (hash cacheado en
`.claude/docker/.image.stamp`, gitignoreado), y monta el `.claude/memory/`
real del repo como `/data` pasando `--user "$(id -u):$(id -g)"` (ver entrada
de ownership mas abajo). Probado de punta a punta simulando exactamente
como lo invocaria `.mcp.json` (`bash .claude/bin/run-memory-mcp-docker.sh`
desde la raiz, handshake `initialize` + `read_graph` por stdin): cargo
correctamente una entidad real del `knowledge-graph.jsonl` de este repo sin
modificarlo, y se confirmo por separado que un cambio de hash SI dispara un
rebuild (fallo solo por falta de red en el sandbox de prueba, no por logica
del script). Para usarlo en una maquina local/WSL con Docker corriendo,
cambiar en `.mcp.json` el `args` de la entry `"memory"` de
`.claude/bin/run-memory-mcp.sh` a `.claude/bin/run-memory-mcp-docker.sh` —
no se cambia por defecto porque el harness remoto no garantiza un daemon de
Docker disponible al arrancar la sesion.

## Manifiesto de bots NARAKIA y skill de dockerizacion (2026-09-12)

- `bots/manifest-narakia.md`: manifiesto versionado de los 4 bots de Make
  (Lucrecia, Natalia, Megan, Paula), con datos VERIFICADOS contra la API real
  de Make (`mcp__Make__scenarios_get`) — modelo, prompt de sistema completo,
  fecha de ultima edicion, estado activo. Incluye riesgos detectados en el
  blueprint real (sin sandboxing de input, link de pago hardcodeado en el
  prompt de Paula, reglas de marca duplicadas en 4 lugares).
- `.claude/skills/mcp-dockerize/SKILL.md`: playbook reutilizable para
  contenedorizar cualquier MCP `command`/stdio de este repo (o de otro repo
  de Estudio Oro), extraido de los bugs reales encontrados al dockerizar el
  server de memoria (PRs #12/#13): chown en build time no sirve contra un
  bind mount, COPY resuelve contra el build context no contra la carpeta del
  Dockerfile, volumen anonimo silencioso si falta el `-v`. Activarlo cuando
  se pida dockerizar/contenedorizar otro MCP.
- Auditoria de sandboxing y de conectores (2026-09-12, ver
  `informes/2026-09-12-auditoria-conectores-mcp.md` y seccion 4.1.2/4.3 del
  informe de Docker): este repo solo controla el MCP `memory` — las **53
  conexiones de terceros** de la cuenta (52 vía `ListConnectors` + GitHub,
  numero verificado con script, no la estimacion "~40" que se uso antes acá)
  se gestionan en Claude.ai, no en archivos de este repo. 5 hallazgos
  concretos, candidatos a revisar (NO todos son solapamiento a resolver: ver
  el informe antes de desconectar nada) en ese informe — Neon/Supabase
  cumplen roles distintos, produccion vs. preview/CI, pendiente confirmar si
  el workflow de preview sigue vigente; 10 plataformas de hosting; 5 canales
  de email; 5 herramientas de ads/SEO; 4 conectores sin proposito
  documentado. Hallazgo real aparte: los 4 bots NARAKIA se
  exponen como MCP tools side-effecting ("EXECUTES the Make scenario
  immediately") — cualquier sesion con el conector de Make activo puede
  disparar un mensaje real sin confirmacion extra mas alla del permiso
  general de la herramienta.

## Credenciales en Make sin scope por escenario (2026-09-13)

`mcp__Make__keys_list` (team 2012148) confirma 6 credenciales guardadas en
Make, todas con `visibility: "team"` (Make no soporta scope por escenario).
La mas sensible, **"Supabase Service Role"** (bypassa RLS por completo),
esta guardada sin ningun escenario activo usandola hoy (`scenarioUsages: []`)
— queda disponible con un clic para cualquiera que edite un escenario nuevo
en ese team. Otras 3 credenciales (Natalia OpenAI x2, Natalia WhatsApp,
Whapi Bearer Token) tambien figuran sin uso activo, candidatas a huerfanas
de una version anterior de los bots. Detalle completo y recomendacion en
`informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md`
seccion 4.3 (checklist de gobierno, item de sandboxing/credenciales).
