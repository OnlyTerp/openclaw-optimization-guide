# Parked: OpenClaw Skills Audit & Install Plan

**Parked on:** 2026-05-03
**Source doc:** `openclaw-knowledge/originals/myclaw-skills-setup.pdf`

## What it is
A full audit of Kevin's OpenClaw setup against high-value community skills, with install recommendations across:

- Web search & research (Brave Search, Browser Relay)
- Browser & desktop control
- Google Workspace (gog)
- Git / GitHub
- Files / CSV / spreadsheets
- Analytics & dashboards
- Marketing & sales (canva-connect, csv-pipeline, check-analytics)
- Cron / cost / ops (api-credits-lite, api-benchmark, aoi-cron-ops-lite)
- Security (antivirus skill for scanning installed skills)
- Canvas / HTML rendering

## Why parked
- Installing skills changes what code runs in Kevin's workspace. That's a security boundary and shouldn't happen at midnight.
- Should be done deliberately, with Kevin able to review each one.
- Bulk-installing 10+ skills creates surface area we don't need yet.

## Single best next move when un-parked
1. Run `openclaw doctor` to see current state.
2. Pick the **3 highest-leverage skills** for Kevin's actual work right now (likely: Brave Search or web research, Google Workspace, and one for cost/ops).
3. Install one at a time. Test. Commit (or roll back).
4. Park the rest until they're actually needed.

## Hard rule
Never auto-install skills. Always Kevin's call, one at a time, with a clear "what does this give us, what does it cost" tradeoff.
