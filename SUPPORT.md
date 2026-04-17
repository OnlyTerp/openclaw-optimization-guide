# Support

A few ways to get help, roughly in order of how fast each one gets you an answer.

## I'm stuck; where do I start?

1. **[Part 27 — Gotchas & FAQ](./part27-gotchas-and-faq.md)** — symptom-indexed. Paste your error; most of them are here.
2. **[Part 28 — Glossary](./part28-glossary-and-terminology.md)** — if a term in the guide is unfamiliar.
3. **[SCORECARD.md](./SCORECARD.md)** — run your setup against the 50-item scorecard. Whatever's unchecked is usually the answer.
4. **[Part 26 — Migration Guide](./part26-migration-guide.md)** — if you suspect a recent OpenClaw upgrade caused the issue.

## I found a bug in the guide

Open an issue using the [Correction template](./.github/ISSUE_TEMPLATE/correction.md). Include:

- The specific Part + line (or a direct GitHub permalink).
- What the guide says.
- What you believe is correct, and a source (release notes, your own test output).
- The OpenClaw version you're on.

## I think something's missing

Open an issue using the [Gap template](./.github/ISSUE_TEMPLATE/gap.md). Describe the scenario you wish the guide covered.

## OpenClaw just cut a new release and the guide hasn't caught up

Open an issue using the [Version Bump template](./.github/ISSUE_TEMPLATE/version-bump.md). Paste the relevant link to the release notes. We usually turn these around within 48 hours of a stable release.

## I have a security-sensitive concern about the guide

See [SECURITY.md](./SECURITY.md). Use GitHub's **private vulnerability reporting** — do not open a public issue.

## I need help with OpenClaw itself, not this guide

This repo isn't the right place. Try these, in order:

1. **[Official docs at clawdocs.org](https://clawdocs.org)**.
2. **[OpenClaw Discord](https://discord.gg/openclaw)** — `#self-hosting` and `#skills-security` are the most responsive channels.
3. **[openclaw/openclaw GitHub issues](https://github.com/openclaw/openclaw/issues)** — if you've localized the problem to the core framework.

## I want to contribute

See [CONTRIBUTING.md](./CONTRIBUTING.md). The short version: corrections are always welcome, new parts land via PRs with at least one real-world example, and style follows the decision-tree + "Read this if / Skip if" pattern established across all existing parts.

## I want to use this guide at my company / in a book / in a talk

Go ahead — it's [MIT-licensed](./LICENSE). A link back is appreciated but not required. If you want to quote specific numbers from [benchmarks/](./benchmarks/), also link the methodology doc alongside so your readers can reproduce them.
