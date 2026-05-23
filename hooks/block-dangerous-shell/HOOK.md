---
name: block-dangerous-shell
description: "Blocks dangerous shell commands: rm -rf /, git push --force to protected branches, curl|sh, dd of=/dev/, and forkbombs. Exit 2 hard-blocks the tool call."
metadata: { "openclaw": { "emoji": "🛡️", "events": ["command:new"] } }
---

# block-dangerous-shell Hook

Fires on `command:new` for exec/bash/powershell tools. Matches against a pattern list of
destructive shell commands and exits 2 (hard block) if any match.

Exit codes: 0 = allow, 2 = block. Never exits 1 (soft error) — this is a safety hook,
failures must block, not silently pass.