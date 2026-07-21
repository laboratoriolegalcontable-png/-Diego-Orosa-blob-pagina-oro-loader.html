---
name: learn
version: 0.1.0
license: MIT
description: |
  English alias for /aprende. Runs the same five-pass workflow to surface
  reusable learnings from the current conversation across memory, lesson,
  skill, and project-doc categories — with confirmation before any write.
  Alias en inglés para /aprende.
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
---

# `learn` — English alias for `/aprende`

This skill is a thin shim. When `/learn` is invoked, follow the **exact**
workflow documented in:

`~/.claude/skills/aprende/SKILL.md`

or, if installed via the plugin, at:

`<plugin-root>/skills/aprende/SKILL.md`

There is no behavior difference between `/learn` and `/aprende`. Both run
the same 5-pass workflow (scan → generate → dedup → confirm → execute),
write to the same memory folders, follow the same guardrails, and produce
identical output. `/learn` exists so English-only users can find it.

For the full instructions, output format, and safety rules, **read
`aprende/SKILL.md` and follow it verbatim**. Do not duplicate logic here.

---

## Quick pointer

- Full workflow: `references/../../aprende/SKILL.md` (sibling skill).
- Output formats: `aprende/references/memory-format.md`,
  `aprende/references/lesson-format.md`.
- Confirmation template: `aprende/prompts/confirmation-template.md`.
