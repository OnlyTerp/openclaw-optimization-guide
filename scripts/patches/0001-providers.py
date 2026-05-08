#!/usr/bin/env python3
"""Idempotently patch ~/.openclaw/openclaw.json to add the balanced-tier
providers, models, and fallback chain. Atomic write (tmp + os.replace).
Aborts non-zero on any read/parse error so the deploy workflow surfaces the
problem instead of silently continuing."""
import json
import os
import sys
from pathlib import Path

CONFIG_PATH = Path.home() / ".openclaw" / "openclaw.json"

KIMI_MODEL = {
    "id": "moonshotai/kimi-k2.6",
    "name": "Kimi K2.6 (OpenRouter)",
    "contextWindow": 131072,
    "maxTokens": 16384,
}

DEEPSEEK_PROVIDER = {
    "baseUrl": "https://api.deepseek.com",
    "auth": "api-key",
    "apiKey": {"source": "env", "provider": "default", "id": "DEEPSEEK_API_KEY"},
    "models": [
        {
            "id": "deepseek-chat",
            "name": "DeepSeek V4 Flash",
            "contextWindow": 65536,
            "maxTokens": 8192,
        }
    ],
}

FALLBACK_CHAIN = [
    "deepseek/deepseek-chat",
    "openrouter/moonshotai/kimi-k2.6",
    "openrouter/google/gemma-3-27b-it:free",
]


def patch(config: dict) -> bool:
    """Apply patches in place. Returns True if anything changed."""
    changed = False

    or_models = config.get("models", {}).get("providers", {}).get("openrouter", {}).get("models", [])
    if not any(m.get("id") == KIMI_MODEL["id"] for m in or_models):
        or_models.append(KIMI_MODEL)
        changed = True

    providers = config.setdefault("models", {}).setdefault("providers", {})
    if "deepseek" not in providers:
        providers["deepseek"] = DEEPSEEK_PROVIDER
        changed = True

    defaults = config.setdefault("agents", {}).setdefault("defaults", {})
    current = defaults.get("model")
    if isinstance(current, str):
        defaults["model"] = {"primary": current, "fallbacks": list(FALLBACK_CHAIN)}
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
        print("Patched: providers + fallback chain updated.")
    else:
        print("No changes needed: providers and fallbacks already present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
