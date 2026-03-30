# Local models are the fast layer

## Key Facts

- Latency under 120ms RTT for 7B parameter models on RTX 5090
- No network hop = zero egress cost, full data privacy
- Hot-swappable via OpenClaw without session restart
- Throughput: 148 tokens/sec with q4_k_m quantization
- Preferred for: agent loops, memory-augmented queries, real-time filtering

## Connected Topics

- [[memory-is-the-bottleneck]] — Why fast inference enables memory-rich workflows
- [[ollama-embedding-setup]] — How to run local embedding backends
- [[vault-philosophy]] — System design principles behind local-first AI

## Agent Notes

- [2026-03-10] Initial insight: local model latency beats API even at $0.0004/token
- [2026-03-12] Tested llama-3.1-8b-instruct vs gpt-4o-mini: 117ms vs 340ms p95
- [2026-03-14] Integrated model hot-swap; agents now self-optimize for task type
- [2026-03-15] Confirmed: local wins on privacy, speed, cost — only scales down for complex reasoning
- [2026-03-16] Deployed fallback to Opus for logic-heavy tasks; hybrid mode live
- [2026-03-17] Benchmark: 8.2x lower cost for token-heavy pipelines using local 7B models
- [2026-03-18] Memory query flow now uses local embedding model + vector cache
- [2026-03-19] Agents auto-select model based on task SLA: speed vs accuracy