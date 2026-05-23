#!/usr/bin/env python3
"""Idempotently apply optimization-guide settings to ~/.openclaw/openclaw.json.

Covers:
  - Part 15: Set explicit compaction model (cerebras/gpt-oss-120b) to prevent
    the Gemini Flash rate-limit crash loop on compaction.
  - Part 23: Disable skill auto-update (ClawHub security).
  - Part 24: Set Task Brain approval policy with control-plane.skills denied.
  - Part 33: Enable messages.visibleReplies for shared-channel surfaces.

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

APPROVAL_POLICY = {
    "read-only.*": "allow",
    "execution.shell": "ask",
    "execution.code": "ask",
    "write.filesystem": "allow",
    "write.network": "ask",
    "control-plane.*": "ask",
    "control-plane.skills": "deny",
}


def patch(config: dict) -> bool:
    changed = False

    # Part 15: compaction model
    defaults = config.setdefault("agents", {}).setdefault("defaults", {})
    compaction = defaults.get("compaction", {})
    if compaction.get("model") != COMPACTION_CONFIG["model"]:
        defaults["compaction"] = {**compaction, **COMPACTION_CONFIG}
        changed = True

    # Part 23: disable ClawHub auto-update
    skills = config.setdefault("skills", {})
    if not skills.get("autoUpdate") is False:
        skills["autoUpdate"] = False
        skills.setdefault("updateNotify", True)
        changed = True

    # Part 24: Task Brain approval policy
    current_approvals = config.get("approvals", {})
    if current_approvals != APPROVAL_POLICY:
        # Merge rather than replace — preserve any existing narrower rules
        merged = {**APPROVAL_POLICY, **current_approvals}
        # Always enforce the hard denies regardless of existing config
        merged["control-plane.skills"] = "deny"
        if config.get("approvals") != merged:
            config["approvals"] = merged
            changed = True

    # Part 33: visible replies for shared-channel surfaces
    messages = config.setdefault("messages", {})
    if not messages.get("visibleReplies"):
        messages["visibleReplies"] = True
        changed = True
    group_chat = messages.setdefault("groupChat", {})
    if not group_chat.get("visibleReplies"):
        group_chat["visibleReplies"] = True
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
        print("Patched: compaction model, skill auto-update, approval policy, visible replies.")
    else:
        print("No changes needed: all optimization settings already present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
