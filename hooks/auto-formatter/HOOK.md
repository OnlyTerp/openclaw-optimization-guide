name: auto-formatter
description: "Runs the appropriate formatter (ruff for Python, prettier for JS/TS, gofmt for Go, rustfmt for Rust, markdownlint for Markdown) on any file the agent writes. Never blocks."
metadata: { "openclaw": { "emoji": "✨", "events": ["command"] } }
---

# auto-formatter Hook

Fires on `command` for edit/write_file/patch tools.

Detects file extension from OPENCLAW_TOOL_ARGS_PATH and runs the appropriate formatter
if available. Never blocks on missing formatters (tools may not be installed).
Always exits 0.
