# Contributing

Thanks for wanting to make the guide better. This is a living document — OpenClaw moves fast, and the only way the guide stays accurate is if people file corrections when they spot something off.

## What to Contribute

**Corrections to existing parts.** If you read something that's wrong, outdated, or confusing, fix it. Short PRs with a clear "this was wrong, this is right" explanation in the description are the easiest to review.

**Version bumps.** When a new OpenClaw version ships with something material (a new config key, a deprecated feature, a new CVE fix), open a PR that:

1. Updates the version line at the top of the README.
2. Adds a "What changed in this release" bullet in the README hero.
3. Updates the specific part(s) that are affected.
4. Adds a row to the migration guide ([Part 26](./part26-migration-guide.md)) if the change is non-trivial.

**New parts.** High bar. A new part should cover a distinct pillar (not a subtopic of an existing part) that's both material and not going to become obsolete in the next release. Open an issue first to discuss — nothing worse than writing 1,500 words of markdown that gets rejected as out of scope.

**Benchmarks.** Real numbers from a real deployment beat prose. If you measured something (search latency, compaction behavior, token reduction from Repowise, etc.), send a PR to `benchmarks/` with the methodology and results.

**Diagrams.** Mermaid is cheap and renders natively on GitHub. If a section would benefit from a diagram, add one.

## What Not to Contribute

- **Speculation.** If you're not sure something is true, don't write it as if it is. Flag uncertainty in the PR description and leave the wording conservative.
- **Marketing copy.** This guide exists because generic marketing docs don't help anyone. Keep claims concrete and cite your source (a release note, a config key, a measurement).
- **Personal-blog posts masquerading as parts.** If your change is really about your specific setup, it probably belongs as an issue comment or a linked external write-up, not a new part.
- **Emoji-heavy rewrites.** The guide uses emoji sparingly for navigation and section markers. Keep prose clean.

## Style

- **Terse > wordy.** Shorter paragraphs, concrete examples, no preambles.
- **Tables for comparisons**, bulleted lists for steps, fenced code blocks for commands.
- **Links > inline duplication.** If something is already covered in another part, link to it.
- **Cross-link new parts** from the relevant existing parts and the README TOC.
- **Consistent heading levels.** Each part starts with `# Part N: Title`, major sections are `##`, subsections `###`.
- **Mark deprecated content** with a block quote at the top saying "DEPRECATED — use [Part X] instead". When a part is fully retired, delete the file and leave a one-paragraph tombstone in the part that supersedes it (see the Part 22 "What Changed (and the Part 16 Retirement)" block in the README for the pattern).

## Running The Quality Checks Locally

```bash
# markdownlint-cli2
npm install -g markdownlint-cli2
markdownlint-cli2 "**/*.md" "#node_modules"

# lychee (link checker)
# macOS/Linux: cargo install lychee  OR  brew install lychee
lychee --offline --no-progress "**/*.md"
# drop --offline to also check external links (slower)
```

CI runs both on every PR via [.github/workflows/docs-quality.yml](./.github/workflows/docs-quality.yml). PRs must pass both checks before merging.

## Opening an Issue

Use [the issue templates](./.github/ISSUE_TEMPLATE/). Summary:

- **Correction** — "This claim in Part X is wrong/outdated."
- **Gap** — "Part X doesn't cover Y, which matters because Z."
- **Version bump** — "OpenClaw vN shipped; here's what needs updating."
- **Question** — before opening, read [Part 27 — Gotchas & FAQ](./part27-gotchas-and-faq.md) first.

## License

Contributions are licensed under the same [MIT license](./LICENSE) as the rest of the guide. Don't send code or content you can't relicense.

## A Note On Tone

The guide has an opinionated voice — short sentences, clear claims, visible frustration with things that shouldn't be this hard. Feel free to write in that register. But stay kind to other contributors in review comments. We're all here to make the guide better.
