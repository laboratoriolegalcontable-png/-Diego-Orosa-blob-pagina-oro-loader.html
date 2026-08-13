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

**BUG CONFIRMADO (2026-07-21), CORREGIDO (2026-08-13 — ver H-01 en
`docs/auditoria-tecnica-integral.md`):** `${CLAUDE_PROJECT_DIR}` en `env.MEMORY_FILE_PATH`
NO se expande en este harness para servidores MCP tipo `command`/stdio (ENOENT
resolviendo contra la carpeta del paquete npm, no el repo). Tampoco funciona una
ruta *relativa* (se probo empiricamente: resuelve contra el directorio interno del
paquete npm instalado por `npx`, no contra el cwd del proceso). La unica opcion que
funciona es una ruta **absoluta** que coincida exactamente con donde este clonado
el repo en el entorno real.

`.mcp.json` quedo con `MEMORY_FILE_PATH=/home/user/-Diego-Orosa-blob-pagina-oro-loader.html/.claude/memory/knowledge-graph.jsonl`,
verificado el 2026-08-13 en esta sesion: se instancio el servidor MCP manualmente
(`npx -y @modelcontextprotocol/server-memory`), se llamo `create_entities` con una
entidad de prueba, se confirmo que escribio en esa ruta, y luego se revirtio el
archivo a su estado vacio original antes de commitear.

**Esta ruta es especifica de este mount/entorno.** Si el repo se clona o monta en
otro path, `MEMORY_FILE_PATH` va a volver a apuntar a un directorio inexistente y
la persistencia va a fallar en silencio (el servidor MCP simplemente no puede
escribir, sin que eso bloquee la sesion). No hay forma conocida en este harness de
resolverlo dinamicamente `[LIMITACION CONOCIDA — revisar si una version futura del
harness soporta expansion de variables en `env` para servidores stdio]`. Antes de
confiar en la persistencia en una sesion nueva: correr `pwd` y comparar contra el
valor de `MEMORY_FILE_PATH` en `.mcp.json`; si no coinciden, actualizar el valor a
mano.
