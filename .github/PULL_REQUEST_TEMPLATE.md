<!-- Ralph PR template. Human PRs can delete this template. -->

## Iteration

Iteration number: <!-- e.g. 03 -->
Iteration title: <!-- copy from IMPLEMENTATION_PLAN.md -->

## What changed

<!-- bullet list of files added/modified -->

## PRESERVE check

- [ ] No changes to `configs/balanced.openclaw.json`
- [ ] No changes to gateway runtime model (still foreground node on port 18789)
- [ ] No additions of `.clawhub/`, `.openclaw/`, or `skills/open-ralph/` to repo
- [ ] No edits to `templates/AGENTS.md`, `templates/SOUL.md`, `templates/MEMORY.md`, `templates/TOOLS.md`, `templates/openclaw.example.json` (unless iteration explicitly authorizes)
- [ ] No edits to `server-config/workspace/` (unless iteration explicitly authorizes)

If any box above is unchecked, this PR includes a proposal in `.ralph/proposals/` and the PRESERVE item is left unchanged on this branch.

## Evidence

<!-- numbers, test output, benchmark results, before/after, file sizes -->

## Rollback plan

<!-- exact steps to revert if this merges and breaks something -->

## Linked artifacts

- Iteration log: `.ralph/iterations/iter-XXX.log`
- Notes (if any): `.ralph/notes.md`
- Proposal (if any): `.ralph/proposals/<topic>.md`
