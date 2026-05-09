---
name: api-credits-lite
description: Display API credit balances for 5 core providers (Anthropic, OpenAI, OpenRouter, Mistral, Groq) with video game style health bars. API auto-checks and manual sync.
optionalEnv:
  - OPENAI_API_KEY
  - OPENROUTER_API_KEY
  - VERCEL_AI_GATEWAY_KEY
permissions:
  - network: Contact OpenAI, OpenRouter, and Vercel APIs to check balances (optional)
  - filesystem: Read/write config.json and health bar display
---

# API Credits Lite

Use this skill when the user asks about API credits, balances, spending, or wants to update their credit info for Anthropic, OpenAI, OpenRouter, Mistral, or Groq.

## When to Use

✅ **USE this skill when the user asks:**

- "How much credit do I have left?" / "What's my balance?"
- "Show my API credits" / "Check my credits"
- "Update my [provider] balance to $X"
- "I topped up [provider] by $X"
- "Am I running low on [provider]?"

❌ **DON'T use when:**
- The user needs 16+ providers, JSONL auto-tracking, cloud SDKs, or heartbeat integration → use **api-credits-pro**

## How to Use

You run the scripts internally — the user never types `python3`. Respond naturally and present health bar output conversationally.

The skill root is at: `~/.openclaw/workspace/skills/api-credits-lite/`
Run scripts with: `python3 <skill-root>/scripts/<script>.py <args>`

---

## Show Credit Balances

**Triggers:** "show my credits", "how much do I have left", "check my API balance"

```bash
python3 scripts/show_credits.py
```

Displays retro health bars for all configured providers. Colors: 🟩 >75% · 🟨 50–75% · 🟧 25–50% · 🟥 <25%

---

## Manual Balance Sync

**Triggers:** "set my Anthropic balance to $X", "update my OpenAI credits to $X", "I have $X left on [provider]"

```bash
python3 scripts/sync_provider.py <provider> <balance>
# With max:  python3 scripts/sync_provider.py <provider> <balance> <max_credits>

# Examples:
python3 scripts/sync_provider.py anthropic 22.97
python3 scripts/sync_provider.py openai 95.00 100.00
```

Supported providers: `anthropic`, `openai`, `openrouter`, `mistral`, `groq`

Where to find balances:
- **Anthropic** → console.anthropic.com
- **OpenAI** → platform.openai.com/usage
- **OpenRouter** → openrouter.ai/activity
- **Mistral** → console.mistral.ai/billing
- **Groq** → console.groq.com/settings/billing

---

## Auto-Check Balance via API

**Triggers:** "check my OpenAI balance automatically", "pull my OpenRouter credits"

For providers that expose a balance API (requires the relevant API key set as an env var):

```bash
python3 scripts/check_openai.py       # uses OPENAI_API_KEY
python3 scripts/check_openrouter.py   # uses OPENROUTER_API_KEY
python3 scripts/check_vercel.py       # uses VERCEL_AI_GATEWAY_KEY
```

Anthropic, Mistral, and Groq don't have public balance APIs — use manual sync for those.

---

## Record a Top-Up

**Triggers:** "I added $X to my [provider] account", "I topped up $50 on OpenRouter"

```bash
python3 scripts/topup.py <provider> <amount>
# Example: python3 scripts/topup.py openrouter 20.00
```

---

## Troubleshooting

If the display shows no providers, the config may be empty. Tell the user to run the first manual sync for each provider they use, or copy the example config:

```bash
cp config.example.json config.json
```

---

## Upgrading

Need 16+ providers, auto-tracking from session logs, cloud SDKs (AWS/Azure/GCP), or heartbeat integration? Suggest **api-credits-pro**.
