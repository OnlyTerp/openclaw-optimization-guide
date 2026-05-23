---
name: skill-install-deny
description: "Blocks skill installation for any slug not in the hardcoded allowlist. The agent physically cannot install skills from un-vetted namespaces."
metadata: { "openclaw": { "emoji": "🚫", "events": ["command:new"] } }
---

# skill-install-deny Hook

Fires on `command:new` for clawhub.install / skill.install tools.

Checks OPENCLAW_TOOL_ARGS_SLUG against an allowlist of trusted namespaces.
Add your org namespace to ALLOWED to permit your own skills.

Exit 2 = hard block. Exit 0 = allow.