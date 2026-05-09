# API Credits Lite

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An **OpenClaw agent skill** — track and display API credit balances across 5 core providers with retro video game health bars. Just ask your agent to check your credits.

## What It Does

- 🎮 **Visual health bars** — at-a-glance credit status for all your providers
- 📊 **5 providers** — Anthropic, OpenAI, OpenRouter, Mistral, Groq
- 🔄 **API auto-check** — automated balance pulls for OpenAI, OpenRouter, Vercel
- 📋 **Manual sync** — update balances from any provider console
- ⚠️ **Low credit alerts** — warning and critical thresholds
- 💰 **Top-up tracking** — record when you add credits

## How to Use

Once installed, just talk to your agent naturally:

> *"How much credit do I have left?"*  
> *"Show my API balances"*  
> *"Update my Anthropic balance to $42.50"*  
> *"I topped up OpenRouter by $20"*  
> *"Am I running low on anything?"*

Your agent handles everything — no commands needed.

## Example Output

```
💰 API Credit Health
━━━━━━━━━━━━━━━━━━━━━

Anthropic 🟧
[████░░░░░░] 42% ($22.97/$54.94)
↳ Last sync: 2m ago

OpenAI 🟩
[██████████] 100% ($100.00/$100.00)

OpenRouter 🟨
[██████░░░░] 60% ($60.00/$100.00)

━━━━━━━━━━━━━━━━━━━━━
⚠️  Anthropic is getting low
```

**Health bar colors:** 🟩 >75% · 🟨 50–75% · 🟧 25–50% · 🟥 <25%

## Installation

Install via [ClawHub](https://clawhub.ai) or clone manually:

```bash
git clone https://github.com/FranciscoBuiltDat/openclaw-api-credits-lite.git
```

Optional: install `requests` for API auto-checks:

```bash
pip install requests
```

## Supported Providers

| Provider | Auto-check | Manual sync | Console URL |
|----------|-----------|-------------|-------------|
| Anthropic | ❌ | ✅ | console.anthropic.com |
| OpenAI | ✅ `OPENAI_API_KEY` | ✅ | platform.openai.com/usage |
| OpenRouter | ✅ `OPENROUTER_API_KEY` | ✅ | openrouter.ai/activity |
| Vercel AI | ✅ `VERCEL_AI_GATEWAY_KEY` | ✅ | vercel.com/dashboard |
| Mistral | ❌ | ✅ | console.mistral.ai/billing |
| Groq | ❌ | ✅ | console.groq.com/settings/billing |

## Pro Version

Need 16+ providers, automatic JSONL tracking from session logs, or heartbeat integration? Upgrade to [api-credits-pro](https://github.com/FranciscoBuiltDat/openclaw-api-credits-pro):

- 🔄 Auto-tracking from OpenClaw session logs (includes prompt caching!)
- 🌐 16+ providers — AWS Bedrock, Azure, GCP Vertex, xAI, Cerebras, and more
- 💓 Heartbeat integration for periodic balance checks
- 📈 Daily/weekly spend analytics

## Contributing

Contributions welcome! Please read [SECURITY.md](SECURITY.md) before contributing.

## License

MIT — see [LICENSE](LICENSE)
