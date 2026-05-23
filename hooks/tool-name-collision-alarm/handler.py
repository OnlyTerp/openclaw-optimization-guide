#!/usr/bin/env python3
# Hook 6: tool-name-collision-alarm
# Detects normalize-collisions between client tools and built-ins at startup.
# Prevents a malicious skill from inheriting built-in trust via name shadowing.
import json
import re
import subprocess
import sys


def normalize(name: str) -> str:
    return re.sub(r'[^a-z0-9]', '', name.lower())


try:
    result = subprocess.run(
        ["openclaw", "tools", "list", "--json"],
        capture_output=True, text=True, timeout=10
    )
    if result.returncode != 0:
        # openclaw not available or tools list failed — don't block startup
        sys.exit(0)

    tools = json.loads(result.stdout)
    seen = {}
    for t in tools:
        n = normalize(t["name"])
        if n in seen and t.get("source") != seen[n].get("source"):
            print(
                f"BLOCKED: normalize-collision between "
                f"{seen[n].get('source')}::{seen[n]['name']} and "
                f"{t.get('source')}::{t['name']}",
                file=sys.stderr
            )
            sys.exit(2)
        seen[n] = t
    sys.exit(0)
except (json.JSONDecodeError, KeyError):
    # Malformed output — don't block startup over a parse error
    sys.exit(0)
except Exception as e:
    print(f"[tool-name-collision-alarm] error: {e!r} — skipping check", file=sys.stderr)
    sys.exit(0)
