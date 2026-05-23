name: session-end-memory-flush
description: "On session end / before compaction, appends a session-summary block to today's dreaming inbox. Feeds the Deep-phase scoring with session signal automatically."
metadata: { "openclaw": { "emoji": "📝", "events": ["session:compact:before"] } }
---

# session-end-memory-flush Hook

Fires on `session:compact:before`.

Appends a timestamped session summary block to memory/dreaming/inbox/YYYY-MM-DD.md.
The dreaming Deep phase reads this file to score and promote learnings to MEMORY.md.

Never blocks — exits 0 even if write fails. Directory is created if needed.
