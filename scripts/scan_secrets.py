#!/usr/bin/env python3
"""Escáner de secretos del repo, usado por .github/workflows/memory-mcp-validate.yml.

Extraído a archivo versionado (H-03/H-02 de docs/auditoria-tecnica-integral.md) para
que sea testeable de forma aislada (ver tests/test_scan_secrets.py) y para poder
ampliar su alcance a todo el árbol versionado por git, no solo a
.claude/memory/knowledge-graph.jsonl.

Uso: python3 scripts/scan_secrets.py [--root PATH]
Exit code 0 = sin hallazgos. Exit code 1 = posible secreto detectado (bloqueante en CI).
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

PATTERN = re.compile(
    r"(api[_-]?key|secret|password|token|bearer)[\"': ]*[A-Za-z0-9_-]{16,}",
    re.IGNORECASE,
)

# Extensiones/paths que no aportan (binarios, lockfiles ruidosos, etc.) — mantener
# esta lista corta y explícita; cualquier exclusión nueva debe justificarse en un PR.
EXCLUDE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".ico"}


def list_tracked_files(root: Path) -> list[Path]:
    """Lista los archivos versionados por git (evita escanear .git/, node_modules/, etc.)."""
    result = subprocess.run(
        ["git", "-C", str(root), "ls-files"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [root / line for line in result.stdout.splitlines() if line]


def scan(root: Path) -> list[tuple[Path, str]]:
    hits = []
    for path in list_tracked_files(root):
        if path.suffix.lower() in EXCLUDE_SUFFIXES or not path.is_file():
            continue
        try:
            text = path.read_text(errors="ignore")
        except OSError:
            continue
        match = PATTERN.search(text)
        if match:
            hits.append((path, match.group(0)[:40]))
    return hits


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="Raíz del repo a escanear")
    args = parser.parse_args()

    hits = scan(Path(args.root).resolve())
    if hits:
        for path, snippet in hits:
            print(f"::error::Posible secreto detectado en {path}: {snippet}...")
        return 1

    print("Sin coincidencias de patrones de secreto en archivos versionados.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
