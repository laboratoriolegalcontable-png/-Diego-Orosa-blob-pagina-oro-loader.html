"""Tests del escáner de secretos (scripts/scan_secrets.py).

Ejecutar con: python3 -m pytest tests/test_scan_secrets.py
o, sin pytest instalado: python3 tests/test_scan_secrets.py
"""
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from scan_secrets import PATTERN  # noqa: E402


def _init_git_repo_with_file(tmp_path: Path, filename: str, content: str) -> Path:
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=tmp_path, check=True)
    subprocess.run(["git", "config", "user.name", "test"], cwd=tmp_path, check=True)
    file_path = tmp_path / filename
    file_path.parent.mkdir(parents=True, exist_ok=True)
    file_path.write_text(content)
    subprocess.run(["git", "add", filename], cwd=tmp_path, check=True)
    return tmp_path


def test_detecta_secreto_con_prefijo_conocido():
    texto = '{"api_key": "abcdef1234567890abcdef"}'
    assert PATTERN.search(texto) is not None


def test_no_detecta_texto_sin_secreto():
    texto = '{"nombre": "consorcio demo"}'
    assert PATTERN.search(texto) is None


def test_gap_conocido_secreto_sin_prefijo_reconocido():
    # Documenta el gap R-05 de docs/auditoria-tecnica-integral.md: un secreto sin una
    # de las palabras clave (api_key/secret/password/token/bearer) cerca no se detecta
    # con esta regex. Este test falla intencionalmente si alguien "arregla" el patrón
    # sin actualizar la documentación del gap.
    texto = '{"valor": "AKIAABCDEFGHIJKLMNOP"}'
    assert PATTERN.search(texto) is None


def test_scan_detecta_archivo_versionado_fuera_del_knowledge_graph(tmp_path):
    # Cubre H-03: el escaneo debe alcanzar cualquier archivo versionado, no solo
    # .claude/memory/knowledge-graph.jsonl.
    repo = _init_git_repo_with_file(
        tmp_path, "config/otro_archivo.json", '{"password": "hardcodeado1234567890"}'
    )
    from scan_secrets import scan  # import diferido: depende de sys.path ya ajustado

    hits = scan(repo)
    assert len(hits) == 1
    assert hits[0][0].name == "otro_archivo.json"


def test_scan_no_reporta_falsos_positivos_en_repo_limpio(tmp_path):
    repo = _init_git_repo_with_file(tmp_path, "readme.txt", "sin secretos aca")
    from scan_secrets import scan

    hits = scan(repo)
    assert hits == []


if __name__ == "__main__":
    # Ejecución manual sin pytest: corre las funciones test_* del módulo.
    import inspect

    mod = sys.modules[__name__]
    failures = 0
    for name, fn in inspect.getmembers(mod, inspect.isfunction):
        if not name.startswith("test_"):
            continue
        sig = inspect.signature(fn)
        if "tmp_path" in sig.parameters:
            with tempfile.TemporaryDirectory() as td:
                fn(Path(td))
        else:
            fn()
        print(f"OK  {name}")
    sys.exit(failures)
