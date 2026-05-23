# Vault Philosophy

## The Network Is The Knowledge
The answer isn't in any single note — it's in the path through connected notes.
Isolated facts age. Connected claims compound.

## Notes Named As Claims
The filename IS the knowledge.
- Bad: `2026-03-19.md`
- Good: `threading-lock-prevents-cuda-concurrent-errors.md`

If you can't name it as a claim, you don't understand it yet. Put it in `00_inbox/`.

## Links Woven Into Sentences
`[[wiki-links]]` go inside sentences, not as footnotes.
- Bad: "See [[nemotron-mamba-wont-train-on-windows]]"
- Good: "Mamba architecture [[nemotron-mamba-wont-train-on-windows]] won't train on Windows due to CUDA graph capture."

## Agent Orients Before Acting
On session start:
1. Scan `01_thinking/` — read MOC filenames
2. On first relevant message: read the matching MOC
3. Follow `[[wiki-links]]` for deeper context
4. After session: update relevant MOC Agent Notes

## Agent Leaves Breadcrumbs
Every session that touches a MOC should update its `## Agent Notes` section.
Format: `- [YYYY-MM-DD] what I did, what I found, what to do next`

## Capture First, Structure Later
New knowledge → `00_inbox/` first, always.
Structure on review, not on capture.
If you can't decide where it goes, leave it in inbox. Do not guess a lane.

## Directory Map
```
vault/
  00_inbox/      ← Raw captures. Dump here, structure later.
  01_thinking/   ← MOCs + synthesized notes. The thinking layer.
  02_reference/  ← External knowledge, tool docs, specs.
  03_creating/   ← Content drafts in progress.
  04_published/  ← Finished work with metadata.
  05_archive/    ← Inactive content. Not deleted, just quiet.
  06_system/     ← This file. Templates, graph index.
```
