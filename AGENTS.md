# AGENTS.md — Ralph Operating Rules for openclaw-optimization-guide

Repo: https://github.com/PeskyE/openclaw-optimization-guide
Default branch: master
Operator: Kevin (PeskyE)
Server: Openclaw-s-2vcpu-2gb-nyc1 @ 167.99.237.49 (clawadmin, Ubuntu 24.04.4, 2vCPU/2GB + 2GB swap)

You are Ralph. You run inside loop.sh on this repo. You read PROMPT.md every iteration. You read this file every iteration. You read IMPLEMENTATION_PLAN.md every iteration and execute the next unchecked iteration.

---

## PRESERVE LIST (DO NOT MODIFY WITHOUT EXPLICIT APPROVAL)

The operator has invested in a working configuration. You are NOT allowed to change any of the following unless the operator explicitly tells you to in IMPLEMENTATION_PLAN.md, AND a change is provably cheaper or more efficient with evidence written into the PR body.

1. configs/balanced.openclaw.json — Sonnet primary, DeepSeek V4 Flash + Kimi K2.6 + openrouter/free fallbacks, Workers default Kimi K2.6, memory-core dreaming cron `0 3 * * *`, memory-lancedb local, Ollama qwen3-embedding:0.6b on localhost:11434, Task Brain approvals as configured. PROPOSE-ONLY. Write proposed diffs into the PR description, never commit changes to this file.
2. Gateway runtime model — gateway runs as foreground node process on port 18789 under user clawadmin via `openclaw gateway start`. Do NOT propose converting to systemd, Docker, pm2, or any daemon manager. Operator confirmed this is intentional.
3. Live server directories — .clawhub/, .openclaw/, skills/open-ralph/ on the server are runtime state. They are intentionally NOT in the repo. Do NOT add them. Do NOT propose adding them.
4. Existing skills/open-ralph implementation on the server — runs OpenCode Zen + ralph CLI. Do NOT replace, refactor, or "consolidate" it.
5. Templates in templates/ — templates/AGENTS.md, templates/SOUL.md, templates/MEMORY.md, templates/TOOLS.md, templates/openclaw.example.json. PROPOSE-ONLY edits. These are user-facing templates; changes affect downstream users.
6. server-config/workspace/ — operator's deployed workspace snapshot. PROPOSE-ONLY.

If you believe a PRESERVE item should change, write the proposal into the active iteration's PR body under a heading "PROPOSED CHANGE TO PRESERVE ITEM" with: current value, proposed value, measured cost or efficiency delta, rollback plan. Then continue with non-PRESERVE work.

---

## ALLOWED EDITS — THE BUILD LANE (this is your runway, use it)

PRESERVE protects the operator's working config and runtime. It does NOT mean stop working. You have a wide additive lane and you are expected to keep building in it across many iterations. Never idle, never write a trivial doc edit just to check a box. If the next iteration in IMPLEMENTATION_PLAN.md is done, pull from this lane:

1. New skill packages under skills/<skill-name>/ — SKILL.md, scripts, examples
2. New hook implementations under hooks/auto-capture/<hook-name>.js with matching docs in part11
3. New library modules under scripts/lib/<module>.js (Memory Bridge, context loaders, embeddings clients, retrieval helpers)
4. New patch scripts under scripts/patches/<patch-name>.sh (idempotent, safe to re-run)
5. New benchmark suites under benchmarks/<bench-name>/ with results.md
6. New examples under examples/<example-name>/
7. New documentation under parts/<category>/<topic>.md following REPO ADDITION MAP
8. New standalone part files part34+, part35+ when content doesn't fit existing categories
9. Bug fixes in scripts/ that are explicitly listed in IMPLEMENTATION_PLAN.md
10. README.md additions that link to new content (append-only, never remove existing sections)
11. .gitignore additions
12. .ralph/ work logs, .ralph/notes.md, .ralph/proposals/<topic>.md
13. PR descriptions, commit messages, branch creation
14. New tests under tests/ or alongside scripts as <name>.test.sh

## KEEP-GOING RULES (do not idle)

- If the next iteration in IMPLEMENTATION_PLAN.md is complete and there are unchecked iterations remaining, start the next one immediately.
- If all numbered iterations are complete but loop.sh is still running (STATUS: COMPLETE not yet written because Phase 7 verification hasn't passed), pull work from the BACKLOG section at the bottom of IMPLEMENTATION_PLAN.md.
- If BACKLOG is empty, generate the next backlog item by reading part12-self-improving-system.md, part19-repowise-codebase-intelligence.md, and part29-hook-catalog.md, picking the highest-leverage missing implementation, and appending it to BACKLOG with a one-paragraph spec. Then execute it.
- Never write a no-op commit. Never write a commit whose only change is whitespace, formatting, or a checkbox tick without a real artifact alongside it.
- A productive iteration produces at least one of: a new file with working content, a new test that passes, a measured benchmark result, a proposal document with evidence in .ralph/proposals/, or a verified bug fix.

## PROPOSAL LANE (when you want to change a PRESERVE item)

PRESERVE is propose-only, not silence. When you have a real reason to change a PRESERVE item:

1. Write .ralph/proposals/<topic>.md with: current value, proposed value, measured cost or efficiency delta with numbers, rollback plan, references to part files that support the change
2. Link it from the active iteration's PR body under heading "PROPOSED CHANGE TO PRESERVE ITEM"
3. Continue with non-PRESERVE work — do not block on the proposal
4. Operator reviews proposals out-of-band and either approves a future iteration to apply them or closes them

---

## DEPLOY WORKFLOW (FROM CLAUDE.md — NON-NEGOTIABLE)

- Never ask the operator to run terminal commands. Server changes go through GitHub Actions deploy on merge to master.
- Always use bare URLs like https://github.com/PeskyE/openclaw-optimization-guide. Never use markdown links [text](url). Never use **bold**. The operator's iPad client breaks them.
- After pushing a branch, always open a PR to merge into master. Never leave a branch unmerged with no PR.
- Branch naming for your commits: claude/<iteration-slug> — e.g. claude/iter-01-memory-bridge, claude/iter-02-phase-0-snapshot.
- One iteration = one branch = one PR. Do not stack iterations on the same branch.
- Never force-push. Never rebase master. Never delete branches.

---

## REPO ADDITION MAP (where to put new content if you propose any)

This is the canonical placement guide. README.md is 116KB and contains parts inline. Standalone part files exist for parts 9-33. When you add new content, follow this map.

Category 1 — Vault & Memory
- Existing: part9-vault-memory.md (36KB), README.md Part 9 starting line 1236
- New content goes in: parts/vault/<topic>.md or part9-vault-memory.md (append)

Category 2 — Embeddings
- Existing: part10-state-of-the-art-embeddings.md
- New content goes in: parts/embeddings/<topic>.md

Category 3 — Auto-Capture Hooks
- Existing: part11-auto-capture-hook.md, hooks/auto-capture/ (currently empty)
- New hook implementations: hooks/auto-capture/<hook-name>.js with matching docs in part11

Category 4 — Self-Improving System
- Existing: part12-self-improving-system.md
- New content goes in: parts/self-improving/<topic>.md

Category 5 — Memory Bridge
- Existing: part13-memory-bridge.md (4575 bytes)
- Implementation: scripts/lib/preflight-context.js (does NOT exist yet — Iteration 1 creates it)

Category 6 — Infrastructure Hardening
- Existing: part15-infrastructure-hardening.md (20KB)
- New: scripts/patches/<patch-name>.sh, parts/infra/<topic>.md

Category 7 — LightRAG / Graph RAG
- Existing: part18-lightrag-graph-rag.md
- New content goes in: parts/lightrag/<topic>.md

Category 8 — RepoWise Codebase Intelligence
- Existing: part19-repowise-codebase-intelligence.md
- New content goes in: parts/repowise/<topic>.md

Category 9 — Observability & Services
- Existing: part20-observability-and-services.md
- New content goes in: parts/observability/<topic>.md

Category 10 — Realtime Knowledge Sync
- Existing: part21-realtime-knowledge-sync.md
- New content goes in: parts/realtime-sync/<topic>.md

Category 11 — ClawHub Skills Marketplace
- Existing: part23-clawhub-skills-marketplace.md
- New content goes in: parts/clawhub/<topic>.md

Category 12 — Task Brain Control Plane
- Existing: part24-task-brain-control-plane.md, configs/balanced.openclaw.json (PRESERVE)
- New content goes in: parts/task-brain/<topic>.md (proposals only — never commit config changes)

README.md inline part anchors (do NOT renumber, do NOT remove):
- Part 1: line 396
- Part 2: line 488
- Part 3: line 610
- Part 4: line 661
- Part 5: line 757
- Part 6: line 946
- Part 7: line 1077
- Part 8: line 1122
- Part 9 (also inline): line 1236
- Part 14: line 1399
- Part 17 (One-Shot, destructive STEP 1-15): line 1466 (steps 1478-1843)
- Part 22 (Built-In Dreaming): line 1843

When you add a new part document, append a single line to README.md's table of contents — do not edit existing TOC entries.

---

## ABSOLUTE BOUNDARY (Phase 0 of every audit)

Before any iteration that modifies files, you must:
1. Read PROMPT.md, AGENTS.md, IMPLEMENTATION_PLAN.md
2. Read CLAUDE.md, SECURITY.md
3. Read configs/balanced.openclaw.json (read-only — never write)
4. Read templates/AGENTS.md, templates/SOUL.md, templates/MEMORY.md, templates/TOOLS.md
5. Confirm the iteration you're about to run is the next unchecked one in IMPLEMENTATION_PLAN.md
6. Confirm your planned changes do not touch any PRESERVE item
7. Create branch claude/<iteration-slug> from master
8. Make changes, commit with message format "iter-NN: <short description>"
9. Push branch, open PR with body containing: iteration number, what changed, what was proposed-only, what evidence supports the change
10. Append iteration log to .ralph/ralph.log
11. Mark the iteration checked in IMPLEMENTATION_PLAN.md (commit this update on the same branch)

---

## DECISION TREE (from templates/AGENTS.md)

For every action, ask in this order:
1. Is this on the PRESERVE list? → propose only, do not commit
2. Is this in ALLOWED EDITS? → proceed
3. Is this in the active iteration of IMPLEMENTATION_PLAN.md? → proceed
4. Otherwise → write to .ralph/notes.md as a future-work item, do not act

---

## TASK BRAIN APPROVAL CATEGORIES (from balanced.openclaw.json — informational, do not change)

- read-only.* → allow
- execution.* → ask
- write.fs.workspace → allow
- write.fs.outside-workspace → deny
- write.network → ask
- control-plane.* → deny

You operate inside write.fs.workspace. You do not have control-plane access. You do not have write.fs.outside-workspace. If an iteration appears to require either, stop and write a NOTES.md proposal instead.

---

## SAFETY

- No force-push, no master commits, no branch deletion, no history rewrite.
- No edits to .github/workflows/ unless an iteration explicitly authorizes it.
- No edits to configs/ unless an iteration explicitly authorizes it (and balanced.openclaw.json never).
- No new dependencies (package.json) unless an iteration explicitly authorizes it.
- No network calls outside scripts/lib/preflight-context.js Memory Bridge calls.
- If you hit an error you don't understand, write the full error to .ralph/notes.md and skip the iteration. Do not guess.

---

## COMPLETION

When IMPLEMENTATION_PLAN.md's Phase 7 verification has run successfully and Phase 8 output summary has been written, append a single line as the last line of IMPLEMENTATION_PLAN.md:

STATUS: COMPLETE

loop.sh greps for this string. It is the only exit-0 signal. Do not write it earlier. Do not write it if any iteration was skipped or any verification failed.
