#!/usr/bin/env python3
"""Chequea que cada .claude/skills/<nombre>/SKILL.md exista, se llame
exactamente SKILL.md (no <nombre>.md) y tenga frontmatter YAML con
"name" y "description". Se corre en cada push/PR."""

import re
import sys
from pathlib import Path

SKILLS_DIR = Path(__file__).resolve().parent.parent / ".claude" / "skills"

FRONTMATTER_RE = re.compile(r"^---\r?\n(.*?)\r?\n---", re.DOTALL)
FIELD_RE = re.compile(r"^([a-zA-Z0-9_-]+):\s*(.*)$", re.MULTILINE)


def parse_frontmatter(text):
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None
    return dict(FIELD_RE.findall(m.group(1)))


def main():
    if not SKILLS_DIR.exists():
        print("[validate-skills] no existe .claude/skills/, nada que validar.")
        return

    errors = []
    dirs = [d for d in SKILLS_DIR.iterdir() if d.is_dir()]

    for skill_dir in dirs:
        files = {f.name for f in skill_dir.iterdir() if f.is_file()}

        wrong_case = next(
            (f for f in files if f.lower() == "skill.md" and f != "SKILL.md"), None
        )
        if wrong_case:
            errors.append(
                f'{skill_dir.name}: el archivo se llama "{wrong_case}", '
                'debe ser exactamente "SKILL.md"'
            )
            continue

        misnamed = f"{skill_dir.name}.md"
        if "SKILL.md" not in files and misnamed in files:
            errors.append(
                f'{skill_dir.name}: tiene "{misnamed}" en vez de "SKILL.md" '
                "(no va a cargar)"
            )
            continue

        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            errors.append(f"{skill_dir.name}: falta SKILL.md")
            continue

        content = skill_md.read_text(errors="ignore")
        frontmatter = parse_frontmatter(content)
        if frontmatter is None:
            errors.append(f"{skill_dir.name}/SKILL.md: sin frontmatter YAML (--- ... ---)")
            continue
        if not frontmatter.get("name"):
            errors.append(f'{skill_dir.name}/SKILL.md: frontmatter sin campo "name"')
        if not frontmatter.get("description"):
            errors.append(f'{skill_dir.name}/SKILL.md: frontmatter sin campo "description"')

    if errors:
        print(f"[validate-skills] {len(errors)} problema(s):\n")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)

    print(f"[validate-skills] OK — {len(dirs)} skills validadas.")


if __name__ == "__main__":
    main()
