# PR 28/29 Recovery Note

PR #28 (`iter-02: Phase 0 safety snapshot`) and PR #29 (`iter-03: Phase 1 repo inventory`) were closed as superseded after their validation failures were traced to `.ralph/` markdown artifacts being included in docs-quality before PR #31 excluded `.ralph/` from markdownlint and lychee.

If GitHub says those old PR branches have conflicts, do not merge those old branches. Open one new PR from this recovery branch instead. This branch contains the regenerated artifacts and excludes the unrelated scorecard/Codex-onboarding files that caused the mixed-branch confusion.

This recovery patch recreates the useful deliverables on the current branch:

- `.ralph/snapshot-phase-0.json`
- `.ralph/snapshot-phase-0.md`
- `.ralph/inventory.md`
- `.ralph/inventory-gaps.md`
- `.ralph/ralph.log`

The `.ralph/` files must be added with `git add -f` because `.ralph/` is ignored for runtime safety. CI should not markdownlint or lychee these files after PR #31.
