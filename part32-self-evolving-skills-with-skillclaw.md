# Part 32: Self-Evolving Skills With SkillClaw

> New in the April 2026 refresh. [SkillClaw](https://github.com/AMAP-ML/SkillClaw) (AMAP Machine Learning, Alibaba) dropped on April 10, 2026, hit 687 stars its first week, and — critically — explicitly lists OpenClaw as a first-class target. The framework turns skills from "frozen playbooks you install once" into a **population that evolves on usage signal**. This part covers how to integrate it.

> **Read this if** you're running more than a few sessions a day and you're tired of manually pruning your skills directory.
> **Skip if** your skills folder is small, static, and you've never had to debug "why did the agent pick skill X over skill Y."

## The Problem SkillClaw Solves

Static skills work fine for the first 20. Past that, you hit:

- **Skill drift.** A skill that worked six months ago now silently fails on a changed dependency, but still gets picked because the agent's selector can't tell.
- **Skill redundancy.** Two skills cover overlapping ground; which one fires is a coin flip.
- **Dead skills.** Never picked, never pruned, still injected into the skill-selection prompt burning tokens.
- **Skill sprawl.** Every debugging session adds a one-off skill. Growth outpaces curation.

The SkillClaw answer: **treat skills as a population with fitness**. Skills that lead to successful outcomes get reinforced. Skills that lead to failures get deprioritized. Skills that never get picked get pruned. The population evolves.

## The Core Idea

Every skill execution produces two signals:

1. **Outcome** — did it work? (task completed, tests green, user accepted, etc.)
2. **Cost** — how much did it cost to pick and run this skill vs. alternatives?

SkillClaw's scheduler stores these across runs and uses them to:

- **Bias future selection.** A skill with a 90% success rate on this kind of task gets a head start over a 40% skill.
- **Generate variants.** When a skill fails in a patterned way, SkillClaw synthesizes a variant (generator-verifier pattern, see [Part 5](./README.md#part-5-orchestration-stop-doing-everything-yourself)) and runs both forward.
- **Prune.** Skills below a floor score over a rolling window get retired.

The mathematical foundation is in *[Mem²Evolve: Experience Memory and Asset Memory Co-Evolution](https://arxiv.org/html/2604.10923v1)* (Apr 14, 2026) — +18.53% improvement over baseline on a mixed agent-task benchmark, achieved entirely through population-level skill evolution rather than model changes.

## The OpenClaw Integration

SkillClaw reads from and writes to OpenClaw's existing skills directory; the integration is purely additive. Install:

```bash
pip install skillclaw
skillclaw init --harness openclaw --skills-dir ./skills
```

This creates:

- `./skills/.skillclaw/population.json` — the current population with per-skill scores.
- `./skills/.skillclaw/trials/` — per-run outcome records. Append-only.
- `./skills/.skillclaw/config.yaml` — evolution parameters (mutation rate, prune floor, population cap).

Wire the scheduler into Task Brain so every flow's outcome becomes a signal:

```json5
{
  "hooks": {
    "SessionEnd": {
      "skillclaw-record": {
        "command": "skillclaw record --outcome ${OPENCLAW_EXIT_STATUS} --skill-invocations ${OPENCLAW_SKILL_TRACE}"
      }
    },
    "PreToolUse": {
      "skillclaw-select": {
        "match": { "tool": ["skill.run"] },
        "command": "skillclaw select --candidate ${OPENCLAW_TOOL_ARGS_SKILL} --task ${OPENCLAW_CURRENT_TASK_TYPE}"
      }
    }
  }
}
```

The `select` hook is advisory — it influences the ranking the model sees, but the model still picks. The `record` hook is what closes the loop.

## Evolution Parameters

Defaults from `skillclaw init`:

```yaml
# skills/.skillclaw/config.yaml
population:
  max_size: 120                 # pop-wide cap; prune below this
  min_trials_before_score: 10   # don't rank until enough data
  score_floor: 0.35             # below this for N windows => prune
  score_floor_windows: 3
evolution:
  mutation_rate: 0.08           # 8% of successful skills spawn variants
  crossover: false              # skill-level crossover is noisy; off by default
  generator_verifier: true      # use Anthropic's generator-verifier pattern
  generation_budget_usd: 0.50   # per new variant
scoring:
  outcome_weight: 0.70          # did the task succeed
  efficiency_weight: 0.20       # token/time cost vs. median
  recency_weight: 0.10          # mild bias toward fresh evidence
```

The default `mutation_rate: 0.08` is conservative. Bump to 0.20 if you want more churn; drop to 0.02 if your production environment can't tolerate a 1-in-12 chance of a new variant showing up in any given session.

## Collective Intelligence Mode

The SkillClaw team's deeper bet, documented in *[SEA-Eval](https://arxiv.org/abs/2604.08377)* (Apr 14, 2026) and their blog, is that skill populations benefit from **pooling signals across deployments**. If 500 OpenClaw installs all independently learn that skill X fails on task Y, the 501st install should start with that prior.

Their opt-in `skillclaw pool` command publishes your (anonymized) skill-outcome records to a shared registry. You get back a monthly-refreshed fitness prior for public skills. This is powerful but operationally spicy:

- **Pro:** Your new deployments inherit a curated skill population from day one.
- **Con:** Your agent's behavior depends on a shared signal you don't fully control. A coordinated group could poison priors.
- **Verdict:** Pool for non-sensitive workloads (public OSS dev, coding practice). Don't pool for production on internal codebases.

## Mem²Evolve: Skills + Memory Co-Evolution

The Mem²Evolve paper goes a step further: it co-evolves the **skill population** and the **memory population**. Not just "which skills work" but "which skills work with which memories." In OpenClaw terms: a skill isn't graded in isolation — it's graded against the MEMORY.md entries active when it fired. Skills that only work when memory X is present get linked to memory X; pruning one prunes the other.

This hasn't landed in the open-source SkillClaw repo yet (as of Apr 17, 2026) but it's the research direction to watch. The practical implication for operators today: **when you delete a MEMORY.md entry, expect skill rankings to shift**. Don't chase the churn — let the population settle over a few days.

## When SkillClaw Is The Right Tool

**Good fit:**

- You have 50+ skills and selection feels like a coin flip.
- You're running many similar sessions (CI, autonomous loops, cron-driven work) so signal accumulates fast.
- You're willing to let the agent's skill selection drift over time in exchange for measurable outcome improvements.

**Bad fit:**

- You have 10 skills and they all do different things. No population, no selection pressure.
- You're in a high-regulation environment where "the agent picked a different skill today than yesterday" is a compliance problem.
- You run very few sessions per week. Signal-per-decision is too low for the loop to converge.

## Further Reading

- *[AMAP-ML/SkillClaw](https://github.com/AMAP-ML/SkillClaw)* — the reference implementation. Created Apr 10, 2026. 687 stars in its first week.
- *[SEA-Eval](https://arxiv.org/abs/2604.08377)* — Apr 14, 2026. The paper SkillClaw was built to evaluate.
- *[Mem²Evolve](https://arxiv.org/html/2604.10923v1)* — Apr 14, 2026. Memory + skill co-evolution results. +18.53% over baseline.
- *[Anthropic — Multi-agent coordination patterns](https://claude.com/blog/multi-agent-coordination-patterns)* — Apr 10, 2026. The generator-verifier pattern SkillClaw uses internally.

## See Also

- [Part 5 — Orchestration](./README.md#part-5-orchestration-stop-doing-everything-yourself) — the coordination patterns SkillClaw's evolution leans on.
- [Part 22 — Built-In Dreaming](./README.md#part-22-built-in-dreaming) — skills and memory both evolve; dreaming is the memory-side pipeline.
- [Part 23 — ClawHub Skills Marketplace](./part23-clawhub-skills-marketplace.md) — static skills; SkillClaw is the dynamic layer on top.
- [Part 24 — Task Brain Control Plane](./part24-task-brain-control-plane.md) — where SkillClaw's signals come from.
- [Part 29 — Hook Catalog](./part29-hook-catalog.md) — the hooks SkillClaw installs to record outcomes.
