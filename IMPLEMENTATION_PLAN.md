# IMPLEMENTATION_PLAN.md — Ralph Audit + Build Plan for openclaw-optimization-guide

Repo: https://github.com/PeskyE/openclaw-optimization-guide
Operator: Kevin (PeskyE)
Plan generated: 2026-05-08
Loop: scripts/ralph-loop.sh (MAX_ITERS=6, MAX_SECONDS=3600, RETRY_LIMIT=1)

Ralph reads this file every iteration. Ralph executes the next unchecked iteration. Ralph commits the checkbox tick on the same branch as the iteration's work. STATUS: COMPLETE is written only after Phase 7 verification passes — never earlier.

---

## ITERATION 0 — Environment Preflight (sanity check before any LLM call)

- [ ] Branch: claude/iter-00-preflight
- [ ] Run scripts/ralph-loop.sh's preflight() in dry-run mode (set MAX_ITERS=0 and exit before the loop) and capture the preflight section of .ralph/ralph.log into .ralph/preflight-report.md
- [ ] Confirm in the report (REQUIRED — block iter-0 if any fail): PROMPT.md / AGENTS.md / IMPLEMENTATION_PLAN.md present at repo root, ANTHROPIC_API_KEY set in environment, claude or opencode CLI on PATH, git remote reachable, gh CLI authenticated, .ralph/ writable. Confirm separately (RECOMMENDED — block iter-1 only): Ollama reachable at localhost:11434 with qwen3-embedding:0.6b pulled. If Ollama is missing, write a clear note to .ralph/notes.md and proceed with iter-0; iter-1 (Memory Bridge) is the first iteration that requires it.
- [ ] If any REQUIRED check fails (see above), write the failure to .ralph/notes.md and STOP — do not advance to iteration 1. Operator fixes the env, re-runs. RECOMMENDED-only failures (e.g. Ollama) do not stop iter-0 — they are noted and surfaced when their dependent iteration runs.
- [ ] If all checks pass, commit .ralph/preflight-report.md
- [ ] Open PR: "iter-00: Environment preflight report"
- [ ] Append to .ralph/ralph.log

## ITERATION 1 — Build Memory Bridge preflight-context.js

- [x] Branch: claude/iter-01-memory-bridge
- [x] Read part13-memory-bridge.md in full
- [x] Read configs/balanced.openclaw.json (read-only) to confirm memory-lancedb path and Ollama qwen3-embedding:0.6b endpoint at localhost:11434
- [x] Create scripts/lib/preflight-context.js implementing the Memory Bridge spec from part13:
  - read repo path from argv or env
  - emit JSON to stdout with: repo summary, recent git log (last 20 commits), open TODO/FIXME counts, file count by extension, top 10 largest files, list of part*.md files with sizes
  - on failure, exit 1 with structured error JSON to stderr — never partial output to stdout
- [x] Create scripts/lib/preflight-context.test.sh that runs preflight-context.js and asserts the JSON has all required keys
- [x] Add a 30-line section to part13-memory-bridge.md documenting the script: invocation, output schema, failure modes
- [x] Open PR: "iter-01: Memory Bridge preflight-context.js"
- [x] Append to .ralph/ralph.log

## ITERATION 2 — Phase 0 Safety Snapshot

- [ ] Branch: claude/iter-02-phase-0-snapshot
- [ ] Run scripts/lib/preflight-context.js > .ralph/snapshot-phase-0.json
- [ ] Generate .ralph/snapshot-phase-0.md containing: current commit SHA, branch, list of all top-level dirs, file count, total repo size, .ralph/ contents, summary of PRESERVE items confirmed present
- [ ] Confirm PRESERVE items are intact: configs/balanced.openclaw.json exists and is unchanged from origin/master, templates/ files intact, scripts/ files intact
- [ ] Commit snapshot files to .ralph/
- [ ] Open PR: "iter-02: Phase 0 safety snapshot"

## ITERATION 3 — Phase 1 Repo Inventory

- [ ] Branch: claude/iter-03-phase-1-inventory
- [ ] Generate .ralph/inventory.md cataloguing:
  - all 21 standalone part*.md files with size, line count, one-paragraph summary each
  - README.md inline part anchors (Part 1 line 396, Part 2 line 488, Part 3 line 610, Part 4 line 661, Part 5 line 757, Part 6 line 946, Part 7 line 1077, Part 8 line 1122, Part 9 inline line 1236, Part 14 line 1399, Part 17 line 1466, Part 22 line 1843)
  - configs/, hooks/, scripts/, templates/, server-config/, examples/, benchmarks/, screenshots/ contents
  - empty or sparse directories (hooks/auto-capture/ is empty — flag as build target)
  - missing implementations referenced in parts but not yet built
- [ ] Generate .ralph/inventory-gaps.md listing every implementation gap as a future iteration candidate
- [ ] Open PR: "iter-03: Phase 1 repo inventory"

## ITERATION 4 — Phase 2 Superpowers Extraction

- [ ] Branch: claude/iter-04-phase-2-superpowers
- [ ] Read part30-ralph-loop-in-openclaw.md, part31-the-llm-wiki-pattern-in-openclaw.md, part32-self-evolving-skills-with-skillclaw.md, part33-late-april-2026-field-guide.md
- [ ] Create skills/ralph-superpowers/SKILL.md documenting: when to invoke, inputs, outputs, decision criteria, examples — based on the four parts above
- [ ] Create skills/ralph-superpowers/examples/ with at least 3 worked examples
- [ ] Append a new TOC line to README.md pointing to the new skill (append-only)
- [ ] Open PR: "iter-04: Phase 2 Ralph superpowers skill"

## ITERATION 5 — Phase 3 Patch Plan

- [ ] Branch: claude/iter-05-phase-3-patch-plan
- [ ] Generate .ralph/patch-plan.md listing every safe, additive change identified in iterations 3 and 4, ordered by leverage
- [ ] For each patch entry: target file or new file path, rationale, risk level (low/medium/high), PRESERVE conflict (yes/no), iteration assignment
- [ ] Patches that touch PRESERVE items go to .ralph/proposals/`[topic]`.md instead, with current/proposed/delta/rollback
- [ ] Open PR: "iter-05: Phase 3 patch plan"

## ITERATION 6 — Phase 4 Apply Safe Changes (deploy bug fixes)

- [ ] Branch: claude/iter-06-phase-4-safe-changes
- [ ] Fix scripts/healthcheck.sh: RETRIES=10 → RETRIES=30, SLEEP=1 → SLEEP=2 (gateway needs ~10-15s to bind port 18789, current values cause false-fail rollbacks per deploy log)
- [ ] Fix scripts/sync-workspace.sh drift detection: exclude .clawhub/, .openclaw/, skills/open-ralph/ from the diff (these are runtime state, not repo content — confirmed by operator)
- [ ] Add scripts/healthcheck.test.sh asserting RETRIES and SLEEP values
- [ ] Update part15-infrastructure-hardening.md with a "Deploy timing tuning" section explaining the fix
- [ ] Open PR: "iter-06: Phase 4 fix healthcheck timing and sync drift detection"

## ITERATION 7 — Phase 5 Ralph Templates

- [ ] Branch: claude/iter-07-phase-5-ralph-templates
- [ ] Create templates/ralph/PROMPT.md.template, templates/ralph/AGENTS.md.template, templates/ralph/IMPLEMENTATION_PLAN.md.template — sanitized versions of the working files in this repo, with placeholder fields for downstream users
- [ ] Create templates/ralph/README.md explaining how to bootstrap Ralph in any repo using the templates
- [ ] Append TOC line to README.md
- [ ] Open PR: "iter-07: Phase 5 Ralph bootstrap templates"

## ITERATION 8 — Phase 6 Hook Proposals

- [ ] Branch: claude/iter-08-phase-6-hooks
- [ ] Read part11-auto-capture-hook.md and part29-hook-catalog.md
- [ ] Implement hooks/auto-capture/git-commit-hook.js (currently the directory is empty)
- [ ] Implement hooks/auto-capture/file-save-hook.js
- [ ] Implement hooks/auto-capture/test-result-hook.js
- [ ] Each hook: stdin JSON event → emits structured memory entry to stdout → exits 0 on success
- [ ] Add hooks/auto-capture/README.md documenting the three hooks
- [ ] Add tests for each hook
- [ ] Open PR: "iter-08: Phase 6 auto-capture hook implementations"

## ITERATION 9 — Phase 7 Verify

- [ ] Branch: claude/iter-09-phase-7-verify
- [ ] Run all *.test.sh files added in iterations 1, 6, 8 — all must pass
- [ ] Run scripts/lib/preflight-context.js end-to-end and confirm output schema
- [ ] Confirm no PRESERVE item has been modified: diff configs/balanced.openclaw.json against origin/master, diff templates/AGENTS.md SOUL.md MEMORY.md TOOLS.md openclaw.example.json against origin/master — all must be identical
- [ ] Confirm every iteration 1-8 has a merged or open PR
- [ ] Confirm .ralph/ralph.log has an entry per iteration
- [ ] Generate .ralph/verify-report.md with results
- [ ] If any check fails, write the failure to .ralph/notes.md and STOP — do not proceed to iteration 10
- [ ] Open PR: "iter-09: Phase 7 verification"

## ITERATION 10 — Phase 8 Output Summary

- [ ] Branch: claude/iter-10-phase-8-output
- [ ] Read .ralph/verify-report.md — proceed only if all checks passed
- [ ] Generate .ralph/audit-summary.md containing: iterations completed, files added, files fixed, PRESERVE items confirmed untouched, proposals written to .ralph/proposals/, open questions for operator, recommended next backlog items
- [ ] Append a new section to README.md titled "Audit log" with one line linking to .ralph/audit-summary.md (append-only)
- [ ] Append the line below as the last line of THIS file (IMPLEMENTATION_PLAN.md):
  STATUS: COMPLETE
- [ ] Open PR: "iter-10: Phase 8 audit summary and completion"

---

## BACKLOG (pull from here when iterations 1-10 are done and loop.sh still has runway)

Ralph: if you finish iteration 10 and loop.sh hasn't exited, OR if you have spare iterations, pull from this list. Each backlog item is a one-paragraph spec. Promote a backlog item to a numbered iteration when you start it (append iteration 11, 12, etc. above this BACKLOG section).

- B1. Implement scripts/lib/embeddings-client.js — local Ollama qwen3-embedding:0.6b client with batching, retry, and a test suite. Documented in part10-state-of-the-art-embeddings.md.
- B2. Implement scripts/lib/lancedb-retrieval.js — wrapper around the local memory-lancedb store for k-NN retrieval used by Memory Bridge. Test against a fixture vault.
- B3. Build skills/repowise/SKILL.md per part19-repowise-codebase-intelligence.md with example invocations against this repo.
- B4. Build skills/lightrag/SKILL.md per part18-lightrag-graph-rag.md.
- B5. Build skills/clawhub/SKILL.md per part23-clawhub-skills-marketplace.md.
- B6. Build benchmarks/embedding-latency/ measuring qwen3-embedding:0.6b throughput on the 2vCPU/2GB droplet.
- B7. Build benchmarks/memory-retrieval/ measuring k-NN recall against a synthetic vault of 10k entries.
- B8. Build examples/ralph-on-fresh-repo/ — a worked example of bootstrapping Ralph on an empty repo using templates/ralph/.
- B9. Build examples/memory-bridge-end-to-end/ — preflight-context.js feeding into a Sonnet call with measured token savings vs. cold context.
- B10. Build scripts/patches/gateway-graceful-restart.sh — idempotent restart that waits for /health 200 before declaring success. Does NOT replace restart-gateway.sh, sits alongside it.
- B11. Document the gateway runtime model in part20-observability-and-services.md: foreground node, port 18789, PID tracking, why not systemd.
- B12. Build skills/skillclaw/SKILL.md per part32-self-evolving-skills-with-skillclaw.md.
- B13. Add part34-ralph-loop-failure-modes.md cataloguing the deploy-bug class of issues (healthcheck timing, drift false positives) with diagnostic recipes.
- B14. Add tests/ralph-loop-smoke.test.sh that runs loop.sh against a fixture repo for one iteration and asserts a PR-shaped branch was produced.
- B15. Build .github/PULL_REQUEST_TEMPLATE.md with sections for: iteration number, PRESERVE check, evidence, rollback plan.

If BACKLOG empties, read part12-self-improving-system.md, part19-repowise-codebase-intelligence.md, part29-hook-catalog.md and append the next highest-leverage missing implementation as B16 with a one-paragraph spec, then execute it.
