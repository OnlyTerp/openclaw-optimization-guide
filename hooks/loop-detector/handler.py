#!/usr/bin/env python3
# Hook: loop-detector
# Warns at 4 consecutive edits to same file, blocks at 6.
# Fails OPEN (exit 0 on hook error) — broken detector must not block work.
import json
import os
import sys
from pathlib import Path

WARN_AT = 4
BLOCK_AT = 6
EDIT_TOOLS = {"edit", "write", "patch", "str_replace_editor", "write_file"}


def main() -> int:
    try:
        session_id = os.environ.get("OPENCLAW_SESSION_ID", "default")
        state_path = Path(f"/tmp/openclaw-loop-{session_id}.json")

        payload = json.load(sys.stdin)
        tool = (payload.get("tool") or "").lower()
        args = payload.get("args", {}) or {}
        path = args.get("file_path") or args.get("path") or args.get("filename")

        if tool not in EDIT_TOOLS or not path:
            return 0

        state = json.loads(state_path.read_text()) if state_path.exists() else {"last": None, "streak": 0}
        if state.get("last") == path:
            state["streak"] = state.get("streak", 0) + 1
        else:
            state = {"last": path, "streak": 1}

        state_path.write_text(json.dumps(state))

        if state["streak"] >= BLOCK_AT:
            print(
                f"BLOCKED by loop-detector: {state['streak']} consecutive edits to {path}. "
                "Stop and reconsider the approach.",
                file=sys.stderr,
            )
            return 2

        if state["streak"] >= WARN_AT:
            print(
                f"[loop-detector] WARNING: {state['streak']} consecutive edits to {path}. "
                "Consider whether the approach is working.",
                file=sys.stderr,
            )

        return 0
    except Exception as e:
        print(f"[loop-detector] hook error ({e!r}) — passing through", file=sys.stderr)
        return 0


if __name__ == "__main__":
    sys.exit(main())
