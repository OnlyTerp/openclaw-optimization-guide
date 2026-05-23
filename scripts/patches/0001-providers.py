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

# Free tier — no API cost, high capability
QWEN3_235B_MODEL = {
    "id": "qwen/qwen3-235b-a22b:free",
    "name": "Qwen3 235B A22B (free)",
    "contextWindow": 131072,
    "maxTokens": 16384,
}

DEEPSEEK_R1_FREE_MODEL = {
    "id": "deepseek/deepseek-r1:free",
    "name": "DeepSeek R1 (free)",
    "contextWindow": 163840,
    "maxTokens": 16000,
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

# Qwen3-235B first (fast MoE, huge context), DeepSeek R1 second (strong reasoning),
# then paid fallbacks. All :free models require no extra key — covered by OpenRouter.
FALLBACK_CHAIN = [
    "openrouter/qwen/qwen3-235b-a22b:free",
    "openrouter/deepseek/deepseek-r1:free",
    "deepseek/deepseek-chat",
    "openrouter/moonshotai/kimi-k2.6",
    "openrouter/google/gemma-3-27b-it:free",
]

FREE_MODELS = [QWEN3_235B_MODEL, DEEPSEEK_R1_FREE_MODEL]

# Cerebras — hardware-accelerated inference, used as the compaction model
CEREBRAS_PROVIDER = {
    "baseUrl": "https://api.cerebras.ai/v1",
    "auth": "api-key",
    "apiKey": {"source": "env", "provider": "default", "id": "CEREBRAS_API_KEY"},
    "models": [
        {
            "id": "gpt-oss-120b",
            "name": "Cerebras GPT-OSS 120B",
            "contextWindow": 128000,
            "maxTokens": 16384,
        }
    ],
}


def patch(config: dict) -> bool:
    """Apply patches in place. Returns True if anything changed."""
    changed = False

    or_provider = config.setdefault("models", {}).setdefault("providers", {}).setdefault("openrouter", {})
    or_models = or_provider.setdefault("models", [])
    existing_ids = {m.get("id") for m in or_models}

    for model in [KIMI_MODEL] + FREE_MODELS:
        if model["id"] not in existing_ids:
            or_models.append(model)
            changed = True

    providers = config.setdefault("models", {}).setdefault("providers", {})
    if "deepseek" not in providers:
        providers["deepseek"] = DEEPSEEK_PROVIDER
        changed = True
    if "cerebras" not in providers:
        providers["cerebras"] = CEREBRAS_PROVIDER
        changed = True

    defaults = config.setdefault("agents", {}).setdefault("defaults", {})
    current = defaults.get("model")
    if isinstance(current, str):
        defaults["model"] = {"primary": current, "fallbacks": list(FALLBACK_CHAIN)}
        changed = True
    elif isinstance(current, dict):
        existing_fallbacks = current.get("fallbacks", [])
        missing = [f for f in FALLBACK_CHAIN if f not in existing_fallbacks]
        if missing:
            current["fallbacks"] = list(FALLBACK_CHAIN) + [
                f for f in existing_fallbacks if f not in FALLBACK_CHAIN
            ]
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
        print("Patched: providers (Cerebras, DeepSeek), free models (Qwen3-235B, DeepSeek R1), and fallback chain updated.")
    else:
        print("No changes needed: providers and fallbacks already present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
