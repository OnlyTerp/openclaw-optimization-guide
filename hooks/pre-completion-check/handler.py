#!/usr/bin/env python3
# Hook: pre-completion-check
# Soft signal — re-reads original ask, compares to current output,
# surfaces gaps. Never blocks (exit 0 always).
import json
import os
import re
import sys


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception as e:
        print(f"[pre-completion-check] could not parse payload: {e!r}", file=sys.stderr)
        return 0

    transcript = payload.get("transcript", [])
    if not transcript:
        return 0

    first_user = next((t for t in transcript if t.get("role") == "user"), None)
    last_assistant = next(
        (t for t in reversed(transcript) if t.get("role") == "assistant"), None
    )
    if not first_user or not last_assistant:
        return 0

    ask = (first_user.get("content") or "").lower()
    out = (last_assistant.get("content") or "").lower()

    asks = re.findall(r"\b(also|and|plus|then|finally|make sure|verify|test|push|commit)\b[^.?!\n]{0,120}", ask)
    misses = [a for a in asks if a.strip().split()[0] not in out]
    if misses:
        print("[pre-completion-check] possible unaddressed asks:", file=sys.stderr)
        for m in misses[:5]:
            print(f"  - {m.strip()}", file=sys.stderr)

    if any(k in ask for k in ("code", "fix", "implement", "build", "refactor")):
        ran_tests = any(
            re.search(r"\b(pytest|npm test|cargo test|go test|bash .*test)\b", json.dumps(t))
            for t in transcript
            if t.get("role") == "tool"
        )
        if not ran_tests:
            print("[pre-completion-check] code task without test run — consider running tests", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
