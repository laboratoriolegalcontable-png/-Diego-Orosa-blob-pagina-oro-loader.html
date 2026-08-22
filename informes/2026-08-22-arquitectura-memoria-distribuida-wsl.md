# Arquitectura de memoria distribuida — Estudio Oro (WSL + Codex + Claude Desktop + Gemini CLI)

> Registro documental. **Esta arquitectura no es parte del proyecto de este repo**
> (`-diego-orosa-blob-pagina-oro-loader.html`); se guarda acá únicamente como
> memoria general del ecosistema de Diego Orosa, a su pedido (2026-08-22).
> Este repo sigue usando su propio servidor MCP `memory` local (ver `CLAUDE.md`
> y `.claude/memory/knowledge-graph.jsonl`), que es independiente del sistema
> descrito abajo.

## Idea central

La memoria deja de vivir "por aplicación" (un `knowledge-graph.jsonl` distinto
por cada repo/asistente) y pasa a vivir **centralizada en WSL Ubuntu**. Claude
Desktop, Codex y Gemini CLI acceden todos a la misma memoria vía MCP, en lugar
de tener cada uno la suya.

## Estructura

```
Windows
├── Codex
│   └── C:\Users\trans\.codex\config.toml
├── Claude Desktop
│   └── C:\Users\trans\AppData\Roaming\Claude\claude_desktop_config.json
├── Gemini CLI
│   └── C:\Users\trans\.gemini\settings.json
└── variable protegida
    └── MODEL_ROUTER_API_KEY

WSL Ubuntu
└── /home/estudiooro/workspace/
    ├── memory/
    │   ├── knowledge-graph.jsonl   ← fuente documental
    │   └── memory.sqlite3          ← búsqueda y metadatos
    └── scripts/
        ├── clients/
        │   ├── memory_mcp_server.py
        │   ├── memory_client.py
        │   ├── task_orchestrator.py
        │   └── fallback_router.py
        └── server/
            ├── memory_ollama_gateway.py
            ├── backup-local.sh
            ├── reindex-memory.sh
            └── server-health.sh
```

## Cómo se guardan las cosas

- La memoria central se guarda en WSL, no en cada aplicación.
- `knowledge-graph.jsonl` conserva los registros documentales.
- `memory.sqlite3` permite buscar por texto, alcance, fuente, confianza y fecha.
- Claude, Codex y Gemini acceden mediante MCP.
- Una escritura sólo ocurre cuando la IA llama explícitamente a `write_memory`;
  no se guarda automáticamente cada conversación.
- Las escrituras duplicadas se deduplican y las versiones distintas se
  conservan.
- La información confidencial queda limitada a Ollama local.
- El backup automático guarda memoria, PostgreSQL, Redis y modelos.
- Tailscale mantiene el acceso privado.

## Configuración de Claude Desktop

`C:\Users\trans\AppData\Roaming\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "estudio_oro_memory": {
      "command": "wsl.exe",
      "args": [
        "-d",
        "Ubuntu",
        "--",
        "python3",
        "/home/estudiooro/workspace/scripts/clients/memory_mcp_server.py"
      ],
      "env": {
        "MEMORY_AGENT_AREA": "transversal"
      }
    }
  }
}
```

## Configuración de Gemini CLI

`C:\Users\trans\.gemini\settings.json`:

```json
{
  "mcpServers": {
    "estudio_oro_memory": {
      "command": "wsl.exe",
      "args": [
        "-d",
        "Ubuntu",
        "--",
        "python3",
        "/home/estudiooro/workspace/scripts/clients/memory_mcp_server.py"
      ],
      "env": {
        "MEMORY_AGENT_AREA": "inmobiliaria"
      }
    }
  }
}
```

Para iniciar Gemini usando el router:

```powershell
$env:MODEL_ROUTER_API_KEY = [Environment]::GetEnvironmentVariable("MODEL_ROUTER_API_KEY", "User")
C:\Users\trans\bin\gemini-oro.ps1
```

## Áreas recomendadas (scopes)

```
penal
inmobiliaria
tecnologia
investigacion
administracion
seguridad
escudo_confianza
transversal
```

## Ejemplo de uso

```
Claude:
"Buscá en memoria los antecedentes del expediente X dentro del área penal."

Gemini:
"Buscá antecedentes de due diligence dentro del área inmobiliaria."

Codex:
"Guardá esta decisión técnica en el área tecnologia."
```

La IA debe guardar información sólo cuando sea útil y explícita, por ejemplo:

```
"Guardá esto en memoria con alcance tecnologia y fuente repo."
```

o:

```
"Guardá este criterio jurídico en penal, con confianza verificada."
```

No queda todo guardado de manera indiscriminada: queda centralizado,
clasificado por área, versionado y respaldado.
