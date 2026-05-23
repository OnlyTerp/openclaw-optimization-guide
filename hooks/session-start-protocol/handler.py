#!/usr/bin/env python3
# Hook: session-start-protocol
# Once per session: surface HOT.md, suggest promotions, archive stale HOT entries.
# Soft signal — never blocks (exit 0 always).
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime, timedelta, timezone
from pathlib import Path


def workspace_root() -> Path:
    return Path(os.environ.get("OPENCLAW_WORKSPACE_ROOT", os.getcwd()))


def main() -> int:
    try:
        root = workspace_root()
        learnings = root / ".learnings"
        hot = learnings / "HOT.md"
        archive = learnings / "archive"
        archive.mkdir(parents=True, exist_ok=True)

        if hot.exists():
            print("[session-start-protocol] active rules from HOT.md:", file=sys.stderr)
            print(hot.read_text(), file=sys.stderr)

        corrections_files = list(learnings.glob("corrections.md")) + list(
            learnings.glob("lanes/*/corrections.md")
        )
        patterns: Counter[str] = Counter()
        for f in corrections_files:
            for line in f.read_text().splitlines():
                key = re.sub(r"^\[\d{4}-\d{2}-\d{2}\]\s*", "", line).strip().lower()
                if key:
                    patterns[key] += 1
        promotions = [k for k, n in patterns.items() if n >= 3]
        if promotions:
            print("[session-start-protocol] promotion candidates (3+ repeats):", file=sys.stderr)
            for p in promotions[:10]:
                print(f"  - {p}", file=sys.stderr)

        if hot.exists():
            cutoff = datetime.now(timezone.utc) - timedelta(days=30)
            kept, moved = [], []
            for line in hot.read_text().splitlines():
                m = re.match(r"\[(\d{4}-\d{2}-\d{2})\]", line)
                if m:
                    ts = datetime.fromisoformat(m.group(1)).replace(tzinfo=timezone.utc)
                    if ts < cutoff:
                        moved.append(line)
                        continue
                kept.append(line)
            if moved:
                stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
                (archive / f"hot-archived-{stamp}.md").write_text("\n".join(moved) + "\n")
                hot.write_text("\n".join(kept) + "\n")
                print(f"[session-start-protocol] archived {len(moved)} stale HOT entries", file=sys.stderr)

        return 0
    except Exception as e:
        print(f"[session-start-protocol] hook error ({e!r}) — passing through", file=sys.stderr)
        return 0


if __name__ == "__main__":
    sys.exit(main())
