# Security Policy

This repository is a documentation guide, not a running service. Still, two kinds of security issue are in scope and worth reporting:

## In scope

1. **Guide content that would make a reader *less* secure if followed.** Example: a config snippet that disables Task Brain approvals, an outdated "rollback" that loses your vault, a skill recommendation that links to a known-compromised author.
2. **Supply-chain issues with files shipped by this repo.** The [`templates/`](./templates/) reference config, the [`hooks/auto-capture/handler.ts`](./hooks/auto-capture/handler.ts), and any future `harness/` scripts are treated as real code for this purpose.

## Out of scope

- Vulnerabilities in OpenClaw itself — report those to the upstream project at [openclaw/openclaw](https://github.com/openclaw/openclaw/security) per their security policy.
- Vulnerabilities in third-party skills you found on ClawHub — report those to the skill author first, then to [ClawHub](https://clawhub.dev) via their disclosure channel.

## How to report

**Do not open a public GitHub issue for security-sensitive reports.** Instead:

1. Open a **private vulnerability report** via [GitHub's Private Vulnerability Reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repo: **Security → Report a vulnerability**.
2. Include: the part of the guide (or the file), the concrete attack or misuse scenario, the minimum fix you think would close it, and any source links.
3. Expect a first response within **7 days**. We'll coordinate a fix and disclosure timeline with you.

## Triage policy

- **Critical** (following the guide literally results in data loss, credential leak, or persistent RCE): we aim to publish a corrected version within 72 hours and cut a tagged release.
- **High** (following the guide literally results in weakened isolation, silent data exfiltration, or downgrade of a Task Brain protection): corrected within 1 week.
- **Medium** (content that's merely out-of-date in a way that could mislead, but with no direct exploit): folded into the next scheduled refresh.

## Acknowledgements

We maintain a short acknowledgements section at the bottom of [CONTRIBUTING.md](./CONTRIBUTING.md) for people who've reported real issues.

Thank you for taking the time to make this guide safer.
