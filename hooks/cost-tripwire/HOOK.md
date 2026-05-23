name: cost-tripwire
description: "Tracks cumulative token spend per session. Warns at 75% of cap, hard-blocks at 100%. Set OPENCLAW_SESSION_CAP_USD env var to override the default $5 cap."
metadata: { "openclaw": { "emoji": "💰", "events": ["agent:bootstrap", "command"] } }
---

# cost-tripwire Hook

Fires on `agent:bootstrap` (initialize session state) and `command` (check spend after each tool).

Reads OPENCLAW_SESSION_ID to namespace state per session. Reads OPENCLAW_SESSION_CAP_USD
for the budget cap (default: $5.00). Fails CLOSED on hook error — a broken tripwire blocks,
not passes, so runaway loops can't sneak through a bad hook.

Exit codes: 0 = under budget, 2 = hard block (cap exceeded or hook error).
