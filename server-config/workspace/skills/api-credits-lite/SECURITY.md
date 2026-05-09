# Security Policy

## Overview

This skill has **two modes**:

1. **Manual Sync (display-only, no network)** — Enter balances manually
2. **Auto-Check (requires API keys, makes network requests)** — Automatically query OpenAI, OpenRouter, or Vercel

Choose the mode that fits your security posture.

## How It Works

### Manual Sync Mode (Display-Only)

```bash
python3 scripts/sync_provider.py anthropic 45.00
python3 scripts/show_credits.py
```

**This mode:**
- ✅ Makes NO network requests
- ✅ Requires NO API keys
- ✅ Only reads/writes local config
- ✅ Safest option for privacy

### Auto-Check Mode (API Key Required)

```bash
OPENAI_API_KEY=sk-... python3 scripts/check_openai.py --update
OPENROUTER_API_KEY=... python3 scripts/check_openrouter.py --update
VERCEL_AI_GATEWAY_KEY=... python3 scripts/check_vercel.py --update
```

**This mode:**
- ⚠️ Makes network requests to provider APIs
- ⚠️ Requires API keys (OPENAI_API_KEY, OPENROUTER_API_KEY, VERCEL_AI_GATEWAY_KEY)
- ✅ Only contacts official provider endpoints (no third parties)
- ✅ Credentials NOT stored or logged locally

## API Keys & Credentials

### How Keys Are Used

**If you provide API keys:**
- Keys are read from environment variables only
- Used to query OpenAI, OpenRouter, or Vercel balance APIs
- NOT stored in config.json or any files
- NOT logged or transmitted anywhere else

### Best Practices

1. **Use Environment Variables (Recommended)**
   ```bash
   export OPENAI_API_KEY="sk-..."
   export OPENROUTER_API_KEY="sk-..."
   export VERCEL_AI_GATEWAY_KEY="..."
   ```
   Never hardcode keys in config or scripts.

2. **Use Minimal-Privilege Keys**
   - Prefer billing-only keys if available
   - Avoid organization admin keys for this tool
   - For OpenAI: use a project-level API key, not org-level

3. **Rotate Keys Regularly**
   - Revoke used keys after testing
   - Consider short-lived keys for automation

4. **Store Keys Securely**
   - Use a password manager or system keychain
   - Load from `.env` file (excluded from git)
   - Never commit to version control

### What's NOT Stored

- ❌ API keys in files
- ❌ Auth tokens anywhere
- ❌ Account identifiers
- ❌ Credential logs

## Network Behavior

### Auto-Check Mode Network Requests

**Destinations (Official APIs only):**
- `api.openai.com` — Check OpenAI org balance
- `api.openrouter.ai` — Check OpenRouter credits
- `api.vercel.com` — Check Vercel balance

**NOT contacted:**
- Unknown third parties
- Tracking services
- Analytics endpoints
- Any server other than the official provider APIs

### Manual Sync Mode Network Requests

**Zero.** No network requests at all.

## Data Storage

### What's Stored Locally

- `config.json` — Credit balances (dollar amounts only)
- Timestamps of last sync
- Provider names

### What's NOT Stored

- API keys
- Auth tokens
- Sensitive credentials
- Personal account information

## File Permissions

Protect your `config.json`:

```bash
# Read/write for owner only
chmod 600 config.json

# View permissions
ls -l config.json
# Should show: -rw------- (600)
```

## Incident Response

If you accidentally expose an API key:

1. **Revoke it immediately**
   - OpenAI: https://platform.openai.com/api-keys
   - OpenRouter: https://openrouter.ai/settings/keys
   - Vercel: https://vercel.com/account/tokens

2. **Generate a new key**

3. **Update your environment variables**

4. **Check your usage** for unauthorized access

## For the Security-Conscious

**If you want zero network access:**
- Use manual sync mode only
- Never set OPENAI_API_KEY, OPENROUTER_API_KEY, or VERCEL_AI_GATEWAY_KEY
- Manually enter balances from provider consoles

**If you want automatic updates:**
- Use auto-check mode
- Provide billing-only or scoped API keys
- Store keys in a password manager, not in files
- Rotate keys periodically

## Audit Status

- **Last audit:** 2026-02-22
- **Status:** ✅ Code reviewed: no exfiltration, no hidden requests
- **Status:** ✅ Network requests only to official provider APIs
- **Status:** ⚠️ Documentation clarified: modes explain network behavior accurately
- **Status:** ✅ No hardcoded credentials
- **Status:** ✅ Keys read from env vars only

## Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email: security@openclaw.dev
3. Include:
   - Description
   - Steps to reproduce
   - Potential impact

Response time: 48 hours

---

**Choose your mode:**
- **Manual = Privacy-first, no keys needed**
- **Auto = Convenient, keys required**

Both are secure IF you follow the practices above.
