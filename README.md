# -Diego-Orosa-blob-pagina-oro-loader.html

Repositorio de soporte y documentación para el ecosistema de Estudio Oro S.A.S. A la fecha no contiene una aplicación web, backend ni frontend: es el lugar donde vive la configuración de memoria persistente MCP de Claude Code para este proyecto, su CI de validación asociado, y documentación técnica y de producto.

## Contenido

| Ruta | Qué es |
|---|---|
| `.mcp.json` | Configuración del servidor MCP `@modelcontextprotocol/server-memory` (knowledge graph persistente entre sesiones de Claude Code). Ver `CLAUDE.md` para detalles y limitaciones conocidas. |
| `.claude/memory/knowledge-graph.jsonl` | Storage del knowledge graph, versionado en git para sobrevivir al reciclado del contenedor. |
| `scripts/scan_secrets.py` | Escáner de secretos usado por el CI. Recorre todos los archivos versionados por git y bloquea el merge si detecta un patrón sospechoso. |
| `tests/test_scan_secrets.py` | Suite de tests del escáner de secretos (7 casos, incluye regresión de falsos positivos). |
| `.github/workflows/memory-mcp-validate.yml` | CI: valida que `.mcp.json` sea JSON válido y corre el escaneo de secretos. Bloqueante. |
| `docs/auditoria-tecnica-integral.md` | Auditoría técnica del repositorio: hallazgos, remediación y checklist reutilizable para cuando exista código de aplicación real. |
| `docs/propuesta-saas-administracion-consorcios.md` | Propuesta de producto para un SaaS de administración de consorcios (Argentina). |

## CI

El workflow `memory-mcp-validate` corre en cada `push` a `main` y en cada `pull_request`. Es bloqueante: falla el check si `.mcp.json` no es JSON válido, o si `scripts/scan_secrets.py` detecta un patrón de secreto en cualquier archivo versionado (con la excepción documentada de `tests/test_scan_secrets.py`, que contiene secretos sintéticos a propósito para testear el propio escáner).

Para correr las mismas verificaciones localmente:

```bash
python3 -c "import json; json.load(open('.mcp.json'))"
python3 tests/test_scan_secrets.py
python3 scripts/scan_secrets.py
```

## Nota sobre `MEMORY_FILE_PATH`

La ruta en `.mcp.json` es absoluta y específica del entorno donde está clonado el repo. Si se clona en otra ubicación, hay que actualizarla a mano — ver el detalle completo en `CLAUDE.md`.
