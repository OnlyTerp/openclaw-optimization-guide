---
name: secret-redact
description: "Rewrites known secret patterns (AWS keys, GitHub PATs, OpenAI/Anthropic keys, GCP keys, private keys, JWTs) to [REDACTED:<kind>] before the model sees them. Runs on both user input and tool output."
metadata: { "openclaw": { "emoji": "🔒", "events": ["message:received", "command"] } }
---

# secret-redact Hook

Fires on `message:received` (user input) and `command` (tool output). Redacts secrets
from both sides of the model boundary before they can appear in context.

Never hard-blocks — redaction should be silent. Exits 0 always.