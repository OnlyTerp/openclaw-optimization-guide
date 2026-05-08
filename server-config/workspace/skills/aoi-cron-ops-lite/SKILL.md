---
name: aoi-cron-ops-lite
description: Cron hygiene and cost-control for OpenClaw. Use to audit/optimize scheduled jobs (cron): detect duplicates, noisy notifications, heavy cadence, repeated failures, and propose safe changes. Default is report-only (no automatic cron updates/removals) and requires explicit user approval before applying schedule changes.
---

# AOI Cron Ops (Lite)

## What this skill does
- Produces a **single, human-readable cron audit report** from an OpenClaw cron job list.
- Flags common ops issues:
  - duplicate purpose (multiple jobs doing the same thing)
  - notification spam (too many announce jobs)
  - over-frequent cadence (high cost / high load)
  - repeated failures / flaky external dependencies
  - missing/invalid env prerequisites (e.g., vault file not present)

## Guardrails (non-negotiable)
- **Lite = report-only by default.**
- Do **not** disable/update/remove cron jobs unless the user explicitly says to apply a specific change.
- When proposing changes, prefer **minimal, reversible** edits:
  - change delivery to `none`
  - slow cadence
  - add a digest job

## Quick start (operator)
1) Get current cron list (JSON):
   - If you have the OpenClaw tool: call `cron(list)` and save output.
   - If you are on terminal: `openclaw cron list --json > cron_jobs.json` (if available).

2) Run analyzer:
```bash
python3 skills/aoi-cron-ops-lite/scripts/analyze_cron_jobs.py --in cron_jobs.json
```

## Output format (expected)
- 10–25 lines:
  - totals (enabled/disabled)
  - top risks (1–5)
  - recommended actions (grouped)
  - “apply plan” (explicit patches to run, but not executed)

## Pro version boundary (for later)
- Pro may auto-apply safe patches (with policy + approvals), generate PR-like diffs for cron config, and maintain a history ledger.
- Lite must never auto-apply.
