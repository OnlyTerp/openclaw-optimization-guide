#!/usr/bin/env python3
"""Idempotently apply optimization-guide settings to ~/.openclaw/openclaw.json.

Covers:
  - Part 15: Set explicit compaction model (cerebras/gpt-oss-120b) to prevent
    the Gemini Flash rate-limit crash loop on compaction.
  - Part 33: Enable messages.visibleReplies for shared-channel surfaces.
    OpenClaw requires the string "automatic" not a boolean.

Note: skills.autoUpdate and approvals wildcard keys were removed — those
field names are not recognized by this version of OpenClaw.

Atomic write (tmp + os.replace). Aborts non-zero on any read/parse error."""
import json
import os
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".openclaw" / "openclaw.json"

COMPACTION_CONFIG = {
    "model": "cerebras/gpt-oss-120b",
    "mode": "safeguard",
    "reserveTokens": 8000,
    "maxActiveTranscriptBytes": 300000,
}

VISIBLE_REPLIES_VALUE = "automatic"


def patch(config: dict) -> bool:
    changed = False

    # Part 15: compaction model
    defaults = config.setdefault("agents", {}).setdefault("defaults", {})
    compaction = defaults.get("compaction", {})
    if compaction.get("model") != COMPACTION_CONFIG["model"]:
        defaults["compaction"] = {**compaction, **COMPACTION_CONFIG}
        changed = True

    # Part 33: visible replies — value must be "automatic" or "message_tool"
    messages = config.setdefault("messages", {})
    if messages.get("visibleReplies") != VISIBLE_REPLIES_VALUE:
        messages["visibleReplies"] = VISIBLE_REPLIES_VALUE
        changed = True
    group_chat = messages.setdefault("groupChat", {})
    if group_chat.get("visibleReplies") != VISIBLE_REPLIES_VALUE:
        group_chat["visibleReplies"] = VISIBLE_REPLIES_VALUE
        changed = True

    return changed


def atomic_write(path: Path, data: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)


def main() -> int:
    if not CONFIG_PATH.exists():
        print(f"ERROR: {CONFIG_PATH} does not exist", file=sys.stderr)
        return 1
    try:
        with CONFIG_PATH.open() as f:
            config = json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: {CONFIG_PATH} is not valid JSON: {e}", file=sys.stderr)
        return 1

    if patch(config):
        atomic_write(CONFIG_PATH, config)
        print("Patched: compaction model + visible replies.")
    else:
        print("No changes needed: all optimization settings already present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
