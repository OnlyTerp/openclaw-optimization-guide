# OpenClaw Scorecard Audit

Generated: 2026-05-10
Evidence folder: /root/openclaw-scorecard-evidence/20260510T032344Z
Probe command: scripts/probes/openclaw-scorecard-probe.sh

Scope note: this audit is evidence from the current execution environment, not the live droplet. The current environment has no openclaw CLI, no ~/.openclaw config, no gh CLI, no origin remote, no crontab command, and no Ollama/OpenClaw gateway process evidence. Live-droplet scoring remains blocked until the probe runs on the droplet or through the configured GitHub remote-exec workflow.

| Pillar | Item | Status | Score | Evidence | Fix Needed |
|---|---|---:|---:|---|---|
| Speed | SOUL.md under 1 KB | PARTIAL | 1 | Repo template is 829 bytes in evidence context_files_sizes.txt. Actual loaded ~/.openclaw/SOUL.md not found. | Verify loaded runtime file on droplet. |
| Speed | AGENTS.md under 2 KB | BROKEN | 0 | Repo template is 3057 bytes; repo root AGENTS.md is 12517 bytes in evidence context_files_sizes.txt. | Runtime AGENTS.md must be checked and trimmed only if it is the loaded runtime file. |
| Speed | MEMORY.md under 3 KB and pure index | PARTIAL | 1 | Repo template is 979 bytes in evidence context_files_sizes.txt. Actual loaded ~/.openclaw/MEMORY.md not found. | Verify loaded runtime file on droplet. |
| Speed | TOOLS.md one-liners under 1 KB | PARTIAL | 1 | Repo template is 395 bytes in evidence context_files_sizes.txt. Actual loaded ~/.openclaw/TOOLS.md not found. | Verify loaded runtime file on droplet. |
| Speed | Total injected context under 8 KB | UNVERIFIED_BLOCKED | 0 | No OpenClaw runtime or turn logging available in openclaw_version.txt and loaded_context_guess.txt. | Run probe on live OpenClaw host and capture actual loaded context. |
| Speed | contextPruning cache-ttl with 5-minute TTL | PARTIAL | 1 | Repo config mentions contextPruning in loaded_context_guess.txt. Live loaded config not found. | Verify live config path and effective value. |
| Speed | Reasoning off by default, on only for orchestration | UNVERIFIED_BLOCKED | 0 | Live model runtime unavailable. | Verify effective model profiles on droplet. |
| Speed | Cheap non-reasoning compaction model | UNVERIFIED_BLOCKED | 0 | No live OpenClaw config/root found. | Verify compaction model in effective config. |
| Speed | Cron output isolated | UNVERIFIED_BLOCKED | 0 | crontab command missing in crontab.txt and no live cron evidence. | Probe on droplet. |
| Speed | localModelLean for small local models | UNVERIFIED_BLOCKED | 0 | No live effective local model config found. | Verify on droplet if local models are used. |
| Memory | Claim-named vault structure | UNVERIFIED_BLOCKED | 0 | memory_dirs.txt did not find live vault evidence. | Probe live vault path. |
| Memory | MOC under vault/01_thinking | NOT_FOUND | 0 | memory_files.txt did not show MOC under live vault. | Create after live vault path is confirmed. |
| Memory | memory_search rule in loaded AGENTS | PARTIAL | 1 | Repo template contains memory_search; live loaded AGENTS not found. | Verify live AGENTS.md. |
| Memory | Local Ollama embeddings qwen3-embedding | UNVERIFIED_BLOCKED | 0 | No Ollama process evidence in processes.txt. | Probe droplet localhost:11434. |
| Memory | Search latency under 150ms warm | UNVERIFIED_BLOCKED | 0 | No memory service available locally. | Run latency benchmark on live vault. |
| Memory | memory-core dreaming nightly | UNVERIFIED_BLOCKED | 0 | No live config or crontab evidence. | Probe droplet config and cron. |
| Memory | Dream phase blocks separate | UNVERIFIED_BLOCKED | 0 | No live memory/dreaming evidence. | Probe live memory root. |
| Memory | DREAMS.md recent sweep | NOT_FOUND | 0 | memory_files.txt did not find live DREAMS.md. | Verify live memory root before creating. |
| Memory | Auto-capture hook wired | PARTIAL | 1 | Repo has hooks/auto-capture/handler.ts in security_grep.txt; live wiring not proven. | Verify runtime hook registration. |
| Memory | LightRAG if vault >=500 files | UNVERIFIED_BLOCKED | 0 | Vault size not verified. | Count live vault files and then verify LightRAG. |
| Orchestration | Frontier orchestrator configured | PARTIAL | 1 | Repo config and AGENTS preserve text mention Sonnet primary; effective live config not proven. | Verify effective live model. |
| Orchestration | Cheap workers configured | PARTIAL | 1 | Repo preserve text mentions Kimi workers; live config not proven. | Verify effective worker model. |
| Orchestration | Explicit spawn sub-agent rule | PARTIAL | 1 | Repo templates include spawn sub-agent rule. Live loaded AGENTS not found. | Verify live AGENTS.md. |
| Orchestration | Parallel independent tasks pattern | PARTIAL | 1 | Repo templates include parallel independent task rule. | Verify it is loaded at runtime and used. |
| Orchestration | Coordinator Protocol used on real task | PARTIAL | 1 | Repo templates document Coordinator Protocol. Real usage not proven. | Capture Task Brain/session evidence. |
| Orchestration | Self-contained worker prompts | PARTIAL | 1 | Repo templates state worker prompt rule. Real prompts not proven. | Capture session/task evidence. |
| Orchestration | Two fallbacks configured and failover tested | PARTIAL | 1 | Repo preserve text/config references fallbacks. Failover test not proven. | Run controlled failover test on live gateway. |
| Orchestration | Ralph implement-test-loop wired | PARTIAL | 1 | scripts/ralph-loop.sh exists in orchestration_files.txt. Live status not proven. | Verify live process/workflow status. |
| Orchestration | Repowise structural index for code | NOT_FOUND | 0 | orchestration_files.txt found only docs/addendum, no installed Repowise index. | Implement backlog B3/B2 style index. |
| Orchestration | Memory Bridge preflight before agents | PARTIAL | 1 | scripts/lib/preflight-context.js exists in orchestration_files.txt. Invocation by Codex sessions not proven. | Add or verify wrapper/launcher. |
| Security | Task Brain live | UNVERIFIED_BLOCKED | 0 | openclaw CLI missing; openclaw_doctor.txt says command not found. | Probe live host. |
| Security | Semantic approval categories | PARTIAL | 1 | Repo config contains taskBrain approvals in config_grep.txt. Effective live config not proven. | Verify live config. |
| Security | control-plane.* deny | PARTIAL | 1 | Repo config contains control-plane deny in config_grep.txt. | Verify live config. |
| Security | write.fs.outside-workspace deny | PARTIAL | 1 | Repo config contains outside-workspace deny in config_grep.txt. | Verify live config. |
| Security | skills.autoUpdate off | UNVERIFIED_BLOCKED | 0 | No live skills config found. | Verify live config; patch only if supported. |
| Security | ClawHub skills pinned | UNVERIFIED_BLOCKED | 0 | No live skill manifest evidence. | Probe ~/.openclaw and .clawhub on droplet. |
| Security | Source reviewed for installed skills | UNVERIFIED_BLOCKED | 0 | No live installed skill list. | Capture installed skill inventory and review log. |
| Security | Credentials env/keychain only | UNVERIFIED_BLOCKED | 0 | No ~/.openclaw/.env found here; no live config. | Probe with redacted evidence on droplet. |
| Security | Approval UI redacts secrets | UNVERIFIED_BLOCKED | 0 | OpenClaw version unavailable. | Verify version and approval UI behavior. |
| Security | Canvas Model Auth green and hot-reload tested | UNVERIFIED_BLOCKED | 0 | Canvas unavailable. | Verify through live Canvas/OpenClaw. |
| Observability | Task Brain captures all activity | UNVERIFIED_BLOCKED | 0 | openclaw CLI unavailable. | Run openclaw tasks list on live host. |
| Observability | Gateway stale-process cleanup | PARTIAL | 1 | scripts/restart-gateway.sh and healthcheck scripts exist in rollback_files.txt. Live startup not proven. | Verify live startup path. |
| Observability | reserveTokens capped | UNVERIFIED_BLOCKED | 0 | No live effective model config. | Verify live config/version. |
| Observability | doctor after upgrade committed | UNVERIFIED_BLOCKED | 0 | openclaw doctor unavailable. | Run doctor on live host and commit redacted output if policy allows. |
| Observability | LangFuse/OpenTelemetry tracing | NOT_FOUND | 0 | observability_grep.txt found docs, not live tracing config. | Configure only after live requirements are clear. |
| Observability | Auto-capture produces inbox notes | UNVERIFIED_BLOCKED | 0 | Hook code exists, live inbox output not found. | Verify runtime hook output. |
| Observability | .learnings written | PARTIAL | 1 | learnings_dirs.txt found learning-related paths, but not live write activity. | Add smoke test where runtime writes. |
| Observability | Real-time knowledge sync running | UNVERIFIED_BLOCKED | 0 | No live watcher process evidence. | Probe live processes/config. |
| Observability | One-command rollback plan | PARTIAL | 1 | scripts/rollback.sh exists in rollback_files.txt. Test not proven. | Test on disposable workspace. |
| Observability | Rollback tested | UNVERIFIED_BLOCKED | 0 | No rollback test evidence. | Run harmless disposable rollback test. |

Verified subtotal from this environment: 21 / 100. This is not a live-droplet score. It mostly credits repository evidence as PARTIAL and blocks live-only items.
