# OpenClaw Scorecard Final — 2026-05-10

## Executive Summary

Starting score supplied by Kevin: 14 / 100.

New verified score from this execution environment: 21 / 100, but this is not a live-droplet score. It is a repository/local-sandbox evidence score. I am not claiming the live droplet improved because this environment cannot reach or authenticate to the live OpenClaw host, GitHub CLI, OpenClaw CLI, crontab, Ollama, or Canvas.

Band: Stock remains unchanged.

Biggest verified improvements in this PR:

- Added a reusable redacted probe script at scripts/probes/openclaw-scorecard-probe.sh.
- Removed committed .ralph runtime artifacts from the prior bad change.
- Produced an evidence-indexed audit at openclaw-scorecard-audit.md.
- Confirmed the local repo has the Memory Bridge script and rollback/healthcheck assets, but live invocation is still unverified.

Biggest remaining blockers:

- No live droplet access from this environment.
- openclaw CLI is not installed here.
- gh CLI is not installed here.
- No origin remote is configured here.
- ~/.openclaw is not present here.
- Ollama and gateway processes are not present here.

## What I Fixed

### Removed bad committed runtime evidence

- Changed: removed .ralph/notes.md, .ralph/preflight-report.md, and .ralph/ralph.log from the repository.
- Backup path before removal: /root/openclaw-scorecard-evidence/20260510T032053Z/backups
- Command used: git rm -f .ralph/notes.md .ralph/preflight-report.md .ralph/ralph.log
- Verification output summary: git status shows those files staged as removed; .gitignore already ignores .ralph/ runtime state.
- Risk level: low. These were sandbox-specific runtime artifacts and should not be source-controlled.

### Added redacted scorecard probe

- Changed: scripts/probes/openclaw-scorecard-probe.sh
- Backup path: new file, no prior file to back up.
- Command used: scripts/probes/openclaw-scorecard-probe.sh
- Verification output summary: evidence written to /root/openclaw-scorecard-evidence/20260510T032344Z.
- Risk level: low. Script is read-only, avoids sudo, redacts secrets, and writes evidence under ~/openclaw-scorecard-evidence/.

### Added evidence-based audit files

- Changed: openclaw-scorecard-audit.md and this final report.
- Backup path: new files, no prior files to back up.
- Command used: local probe plus manual evidence scoring from SCORECARD.md.
- Verification output summary: audit rows cite probe output filenames and use only allowed statuses.
- Risk level: low. Documentation-only.

## What I Verified But Did Not Change

- Repo template SOUL.md is under 1 KB: 829 bytes in context_files_sizes.txt.
- Repo template MEMORY.md is under 3 KB: 979 bytes in context_files_sizes.txt.
- Repo template TOOLS.md is under 1 KB: 395 bytes in context_files_sizes.txt.
- Repo template AGENTS.md is over the target: 3057 bytes in context_files_sizes.txt. I did not edit templates because templates are on the PRESERVE list.
- scripts/lib/preflight-context.js exists according to orchestration_files.txt.
- scripts/rollback.sh exists according to rollback_files.txt.
- OpenClaw CLI is unavailable here: openclaw_version.txt and openclaw_doctor.txt show command not found.

## What Remains Blocked

- Live OpenClaw verification is blocked by missing live host access in this environment. Needs GitHub Actions remote-exec or an authenticated live shell environment.
- GitHub PR/CI verification is blocked because gh is missing here. Needs GitHub CLI authentication in the environment that will merge or dispatch workflows.
- Live memory, Task Brain, Canvas, Ollama, gateway, and crontab checks are blocked because this container is not the droplet and does not contain ~/.openclaw.
- Safe config fixes are blocked until live effective config paths are proven. Editing configs/balanced.openclaw.json is PRESERVE/propose-only and was not touched.
- Runtime template trimming is blocked until the actual loaded SOUL/AGENTS/MEMORY/TOOLS files are identified on the live host. Repo templates are PRESERVE/propose-only.

## Kevin's Exact Next Steps

DO THIS NOW:
1. Run the redacted probe through the trusted connected environment, preferably the existing GitHub Actions remote-exec workflow, so the evidence comes from the droplet instead of this sandbox.
2. Feed the resulting evidence folder back into the scorecard audit so live-only items can move from UNVERIFIED_BLOCKED to VERIFIED_LIVE or BROKEN.
3. Only after live evidence exists, apply the safe fixes in this order: runtime context file sizes, skills.autoUpdate/deny-rule verification, .learnings smoke test, MOC/DREAMS verification, then Codex Memory Bridge wrapper.

DO NOT DO YET:

- Do not edit configs/balanced.openclaw.json directly.
- Do not trim repo root AGENTS.md as if it were the loaded runtime AGENTS.md.
- Do not restart the gateway from this environment.
- Do not add systemd, Docker, pm2, or daemon-manager changes.
- Do not mark Iteration 0 or the scorecard live items complete from sandbox evidence.

## Updated Scorecard

See openclaw-scorecard-audit.md for all 50 item-by-item rows.

Current evidence-only subtotal from this environment: 21 / 100.

Live droplet score: UNVERIFIED_BLOCKED from this environment.

## Evidence Index

- /root/openclaw-scorecard-evidence/20260510T032344Z/metadata.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/system_basics.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_version.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_doctor.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_memory_status.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_plugins_list.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_skills_list.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/context_files_find.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/context_files_sizes.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/loaded_context_guess.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_config_find.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/config_grep.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/memory_dirs.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/memory_files.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/crontab.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/memory_grep.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/orchestration_files.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/orchestration_grep.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/processes.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/security_grep.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/openclaw_dir_listing.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/secret_permissions.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/user_units.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/system_units.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/learnings_dirs.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/rollback_files.txt
- /root/openclaw-scorecard-evidence/20260510T032344Z/observability_grep.txt
