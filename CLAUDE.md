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

**BUG #2 CONFIRMADO Y CORREGIDO (2026-07-21):** la ruta hardcodeada apuntaba a
`/home/user/pagina-oro-loader/...`, que NO coincide con el nombre real del repo
(`-Diego-Orosa-blob-pagina-oro-loader.html`). El directorio no existia, la memoria
MCP fallaba silenciosamente (ENOENT) y `knowledge-graph.jsonl` quedaba siempre en
0 bytes. Corregido a la ruta real:
`/home/user/-Diego-Orosa-blob-pagina-oro-loader.html/.claude/memory/knowledge-graph.jsonl`.
Como la ruta absoluta sigue hardcodeada (no hay forma de usar `$CLAUDE_PROJECT_DIR`
por el bug de arriba), **si el entorno vuelve a montar el repo en otra ruta, este
bug se repite** — verificar `pwd` vs `MEMORY_FILE_PATH` en `.mcp.json` al empezar
cualquier sesion que dependa de la memoria persistente.
