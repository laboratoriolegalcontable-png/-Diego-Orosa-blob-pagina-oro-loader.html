#!/usr/bin/env bash
# Wrapper para el servidor MCP de memoria: resuelve su propia ubicacion en
# runtime en vez de depender de una ruta absoluta hardcodeada en .mcp.json,
# que rompe silenciosamente si el harness vuelve a montar el repo en otra
# carpeta (bug #1 y #2, ver CLAUDE.md).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MEMORY_DIR="$SCRIPT_DIR/.claude/memory"
mkdir -p "$MEMORY_DIR"
export MEMORY_FILE_PATH="$MEMORY_DIR/knowledge-graph.jsonl"
exec npx -y @modelcontextprotocol/server-memory
