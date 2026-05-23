#!/usr/bin/env python3
# Hook 2: secret-redact
# Rewrites known secret patterns to [REDACTED:<kind>] in both user input and tool output.
# Reads JSON from stdin, writes sanitized JSON to stdout. Always exits 0.
import json
import re
import sys

PATTERNS = [
    ("aws_access_key", r"AKIA[0-9A-Z]{16}"),
    ("aws_secret",     r"(?i)aws[_-]?secret[_-]?(access[_-]?)?key\s*[:=]\s*['\"]?([A-Za-z0-9/+=]{40})"),
    ("github_pat",     r"ghp_[A-Za-z0-9]{36,}"),
    ("openai_key",     r"sk-[A-Za-z0-9]{32,}"),
    ("anthropic_key",  r"sk-ant-[A-Za-z0-9_-]{40,}"),
    ("gcp_key",        r"AIza[0-9A-Za-z_-]{35}"),
    ("private_key",    r"-----BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY-----"),
    ("jwt",            r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}"),
]

try:
    payload = json.load(sys.stdin)
    for field in ("output", "prompt"):
        if field in payload and payload[field]:
            text = payload[field]
            for kind, pat in PATTERNS:
                text = re.sub(pat, f"[REDACTED:{kind}]", text)
            payload[field] = text
    json.dump(payload, sys.stdout)
    sys.exit(0)
except Exception as e:
    # Never block on redaction failure — pass through unmodified.
    sys.exit(0)
