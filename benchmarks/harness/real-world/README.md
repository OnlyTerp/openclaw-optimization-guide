# Real-world task corpus

A small, deliberately messy set of real tasks that agents should be able to complete end-to-end. Paired with the synthetic benchmarks in the parent [`harness/`](../) directory so readers can compare "did the numbers go up?" with "did the agent actually accomplish something useful?"

> **Status: scaffold.** This directory is a placeholder. The task corpus is built out via community contributions — see [../../METHODOLOGY.md §7](../../METHODOLOGY.md#7-roadmap).

## What goes here

Each task lives in its own subdirectory with this shape:

```text
harness/real-world/
  migrate-legacy-codebase/
    README.md          # task brief (what the agent should do)
    starting-state/    # initial files the agent sees
    oracle/            # ground-truth solution (used for grading, NOT shown to the agent)
    grade.sh           # script that compares agent output to oracle; exits 0/1
  triage-bug-backlog/
    ...
  rewrite-docs-site/
    ...
```

## Initial task backlog (not yet implemented)

| Task | Pillar it stresses | Expected difficulty |
|---|---|---|
| `migrate-legacy-codebase` | Orchestration, Memory | Hard |
| `triage-bug-backlog` | Memory, Observability | Medium |
| `rewrite-docs-site` | Orchestration, Speed | Medium |
| `fix-one-cve` | Security, Observability | Easy |
| `ship-a-skill` | Security, Orchestration | Medium |

## Grading contract

- `grade.sh` must be deterministic and not depend on LLM-as-judge. (LLM judging is welcome as a *supplementary* signal, but never as the gate.)
- A task is either `pass` or `fail`. No partial credit; partial credit is noise.
- The oracle directory is read-only to the agent. If the agent peeks, the result is void.

## How to contribute a task

1. Open an issue with `[real-world benchmark]` in the title describing the task.
2. Once confirmed, open a PR adding the subdirectory following the structure above.
3. Include at least one `runs/*.md` entry where the task was graded so reviewers can see the grading script working end-to-end.

See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for the general PR workflow.
