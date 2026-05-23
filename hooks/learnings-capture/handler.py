#!/usr/bin/env python3
# Hook: learnings-capture
# Mechanical, single-line appends to .learnings/{ERRORS,corrections,LEARNINGS}.md.
# Soft signal — never blocks (exit 0 always).
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

LOCKED_LANES = {"coparenting", "co-parenting", "school-advocacy", "school_advocacy"}


def workspace_root() -> Path:
    return Path(os.environ.get("OPENCLAW_WORKSPACE_ROOT", os.getcwd()))


def append_line(path: Path, line: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(line.rstrip() + "\n")


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0

    event = (payload.get("event") or "").lower()
    lane = (payload.get("lane") or "").strip().lower()
    locked = lane in LOCKED_LANES

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    root = workspace_root() / ".learnings"

    def target(base_name: str) -> Path:
        if lane and locked:
            return root / "lanes" / lane / base_name
        if lane:
            return root / "lanes" / lane / base_name
        return root / base_name

    if event == "tool:error":
        tool = payload.get("tool", "?")
        msg = re.sub(r"\s+", " ", str(payload.get("message", "")).strip())[:240]
        guidance = re.sub(r"\s+", " ", str(payload.get("guidance", "")).strip())[:240]
        line = f"[{today}] [{lane or 'shared'}] {tool}: {msg}"
        if guidance:
            line += f" → {guidance}"
        append_line(target("ERRORS.md"), line)

    elif event == "command:correction":
        correction = re.sub(r"\s+", " ", str(payload.get("correction", "")).strip())[:480]
        if correction:
            append_line(target("corrections.md"), f"[{today}] [{lane or 'shared'}] {correction}")

    elif event == "command:discovery":
        discovery = re.sub(r"\s+", " ", str(payload.get("discovery", "")).strip())[:480]
        if discovery:
            append_line(target("LEARNINGS.md"), f"[{today}] [{lane or 'shared'}] {discovery}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
