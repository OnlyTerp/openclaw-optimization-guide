---
name: auto-capture
description: "Automatically extracts knowledge from conversations and saves claim-named notes to vault/00_inbox/"
metadata: { "openclaw": { "emoji": "🧠", "events": ["command:new", "command:reset", "session:compact:before"] } }
---

# Auto-Capture Hook

Fires on /new, /reset, and before compaction. Extracts facts, decisions, and insights from the conversation and saves them as claim-named markdown notes to vault/00_inbox/.
