# Gateway único de MCP

`mcp-gateway.mjs` es un servidor MCP `command`/stdio que agrega otros servidores
MCP `command`/stdio declarados en `gateway.config.json`, para que `.mcp.json`
tenga **una sola entry** ("gateway") en vez de una por backend. Contexto y
motivación completos en los comentarios al inicio de `mcp-gateway.mjs` y en
`informes/2026-09-11-docker-state-of-agentic-ai-aplicado-narakia.md` /
`informes/2026-09-12-auditoria-conectores-mcp.md`.

## Estado actual

**No es el default de `.mcp.json` todavía** — hoy `.mcp.json` sigue apuntando a
`memory` directo (`.claude/bin/run-memory-mcp.sh`), igual que la versión Docker
del mismo server. Con un solo backend, el gateway no aporta nada por sí solo;
el valor aparece cuando se agregan más servidores `command`/stdio propios de
este repo. Para activarlo, cambiar en `.mcp.json`:

```json
{
  "mcpServers": {
    "gateway": {
      "command": "node",
      "args": [".claude/gateway/mcp-gateway.mjs"]
    }
  }
}
```

Las tools de cada backend quedan expuestas con el prefijo `<backend>__`, ej.
`memory__read_graph`, `memory__create_entities` — necesario porque dos
backends distintos podrían declarar una tool con el mismo nombre.

## Agregar un backend

Un objeto más en el array `backends` de `gateway.config.json` — no hace falta
tocar `mcp-gateway.mjs`:

```json
{ "name": "otro", "command": "bash", "args": [".claude/bin/run-otro-mcp.sh"] }
```

`name` solo admite `[a-zA-Z0-9_-]` (se usa como prefijo de tool, y `__` es el
separador — no usar `__` dentro del nombre).

## Cómo se probó (antes de decir que "funciona")

Igual que `mcp-dockerize/SKILL.md`, no alcanza con que el proceso arranque —
hay que probar el protocolo real:

1. **Handshake completo por stdin/stdout**: `initialize` → `notifications/initialized`
   → `tools/list` → `tools/call`, contra `memory` como backend real, verificando
   que `tools/list` devuelve las 9 tools de `memory` con el prefijo `memory__`
   y que `tools/call` a `memory__read_graph` devuelve el grafo real.
2. **No mutar el archivo real del repo**: backup de
   `.claude/memory/knowledge-graph.jsonl` antes de la prueba de lectura, diff
   después — sin cambios. La prueba de **escritura** (`memory__create_entities`)
   se corrió aparte, contra una copia del repo en `/tmp`, nunca contra el
   archivo versionado.
3. **Métodos no soportados y nombres de tool mal formados**: `resources/list` y
   `prompts/list` devuelven listas vacías (no rompen al cliente), un método
   inexistente devuelve `-32601`, y una tool sin el separador `__` o con un
   backend inexistente devuelve `-32602` con un mensaje explicando el formato
   esperado.
4. **Cierre limpio**: al cerrarse stdin (fin de la sesión MCP), el gateway
   espera los mensajes todavía en vuelo y después mata los procesos backend —
   se verificó que no queda ningún proceso `server-memory`/`npx` corriendo
   después de que el gateway termina.
5. **Bug real encontrado y corregido durante esta prueba** (condición de
   carrera): la primera versión marcaba "backends ya inicializados" con un
   booleano seteado ANTES de esperar la inicialización real — un mensaje
   concurrente (ej. `tools/list` llegando justo después de
   `notifications/initialized`) pasaba de largo contra una lista de tools
   todavía vacía. Fix: guardar la `Promise` en curso en vez de un booleano, así
   toda llamada concurrente espera esa misma promise. Ver el comentario en
   `ensureBackendsInitialized()` en el código.

## Limitación conocida (no es un bug del gateway)

`@modelcontextprotocol/server-memory` (backend `memory`, versión pinneada
`2026.8.31` según el Dockerfile / `0.6.3` real reportado en su propio
`initialize`) **no serializa sus operaciones de lectura/escritura**: si dos
tool calls contra el mismo backend se mandan sin esperar la respuesta de la
primera (ej. `create_entities` seguido inmediatamente de `read_graph`, sin
esperar la respuesta de `create_entities`), `read_graph` puede devolver el
estado *anterior* a la escritura, y las respuestas pueden llegar en un orden
distinto al de las llamadas. **Verificado que el gateway no introduce ni
empeora esto**: se reprodujo exactamente el mismo comportamiento invocando
`server-memory` directo por stdio, sin el gateway de por medio (mismo input,
mismo resultado). Es una limitación del paquete upstream, no algo para
"arreglar" acá — un gateway debe ser un proxy transparente, no cambiar la
semántica del backend. Si esto llega a importar en la práctica (llamadas en
paralelo reales del cliente MCP contra `memory`), la mitigación es evitar
pipelinear llamadas de escritura y lectura consecutivas contra el mismo
backend sin esperar la respuesta — no algo que el gateway pueda garantizar
por sí solo sin agregar una cola de serialización por backend (no implementada
todavía, evaluar si hace falta antes de poner esto como default).
