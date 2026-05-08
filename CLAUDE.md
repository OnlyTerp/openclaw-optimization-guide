# CLAUDE.md — Session Instructions for PeskyE/openclaw-optimization-guide

## Always Do After Pushing a Branch
After pushing any changes to a branch, always open a pull request to merge it into `master`.

## Repo Context
This is the openclaw-optimization-guide repo. Config files live in `configs/`. The main reference config is `configs/balanced.openclaw.json`.

## Git Workflow
1. Make changes on a feature branch
2. Commit with a clear message
3. Push to origin
4. Open a PR to merge into master — do this every time without being asked

## Formatting
- When sharing URLs, never wrap them in markdown formatting (no `**bold**`, no `[text](url)`). The user's iPad client breaks links inside markdown formatting. Always use bare URLs like `https://github.com/...`

## Never Ask the User to Run Terminal Commands
- The user has the auto-deploy workflow set up (`.github/workflows/deploy.yml`). Any change to their server should go through that workflow, not through terminal commands.
- Workflow: edit files in the repo → push to a branch → open a PR → user clicks merge → server auto-updates.
- Do NOT ask the user to `bash`, `cat`, `grep`, `nano`, or run any other terminal command on their server. If you need server-side info, extend the deploy workflow to gather and report it (e.g., write findings to a file in the repo, or echo to the action logs).
- The only exception is one-off diagnostics where the deploy workflow itself is broken and can't be used.
