---
name: vault-orientation
description: "Fires on first touch of vault/ in a session. Enforces vault structure (claim-named files, MOC routing, wiki-links woven into sentences), Agent Notes updates, and the inbox-first rule for new captures."
triggers:
  - "vault/"
  - "vault orientation"
  - "moc"
  - "map of contents"
  - "claim-named"
  - "wiki-link"
metadata: { "openclaw": { "emoji": "📚", "events": ["fs:touch:vault"] } }
---

# vault-orientation Skill

Replaces the "Vault Orientation Protocol" prose previously living in AGENTS.md.

## Rules

1. **New knowledge → `vault/00_inbox/`** with a claim-named file (`why-X-happens.md`, not `notes-today.md`).
2. **Use `[[wiki-links]]` woven into sentences**, not as footnotes.
3. **After touching a topic: update the relevant MOC's `## Agent Notes` section.** Format: `- [YYYY-MM-DD] what I did, what I found, what to do next`.
4. **Vault structure:**
   - `00_inbox/` — raw captures, always land here first
   - `01_thinking/` — MOCs + synthesized notes
   - `02_reference/` — external docs, specs, tool references
   - `03_creating/` — drafts in progress
   - `04_published/` — finished work
   - `05_archive/` — inactive, not deleted
   - `06_system/` — vault-philosophy.md, templates, graph index, system pointers

Full philosophy: `vault/06_system/vault-philosophy.md`.
