#!/usr/bin/env python3
# Hook 3: cost-tripwire
# Tracks cumulative session spend. Warns at 75% of cap, hard-blocks at 100%.
# Fails CLOSED: a hook error exits 2 (block) not 1 (continue).
import json
import os
import sys
from pathlib import Path

try:
    SESSION_ID = os.environ.get("OPENCLAW_SESSION_ID", "default")
    STATE = Path(f"/tmp/openclaw-cost-{SESSION_ID}.json")
    CAP_USD = float(os.environ.get("OPENCLAW_SESSION_CAP_USD", "5.00"))

    payload = json.load(sys.stdin)
    usage = payload.get("usage", {})
    spend = usage.get("cost_usd", 0.0)

    total = json.loads(STATE.read_text())["total"] if STATE.exists() else 0.0
    total += spend
    STATE.write_text(json.dumps({"total": total}))

    if total >= CAP_USD:
        print(f"BLOCKED by cost-tripwire: session spend ${total:.2f} exceeded cap ${CAP_USD:.2f}", file=sys.stderr)
        sys.exit(2)

    if total >= 0.75 * CAP_USD:
        print(f"[cost-tripwire] WARNING: ${total:.2f} / ${CAP_USD:.2f} used", file=sys.stderr)

    sys.exit(0)
except Exception as e:
    # Fail CLOSED: broken tripwire must block, not silently pass.
    print(f"BLOCKED by cost-tripwire: hook error ({e!r}) — refusing to run without cost tracking", file=sys.stderr)
    sys.exit(2)
