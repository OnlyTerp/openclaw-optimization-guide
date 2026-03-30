# Ollama Embedding Setup

```bash
# Start Ollama with embedding model
ollama run bge-m3

# Verify it's running
curl http://localhost:11434/api/generate -d '{"model": "bge-m3", "prompt": "test"}'

# Run local embedding server (if using qwen3-vl-embedding-8b)
CUDA_VISIBLE_DEVICES=0 ollama run qwen3-vl-embedding-8b

# Use in memory-query script
node scripts/memory-bridge/memory-query.js "what are local models?"

# Check active models
ollama list

# Pull latest embedding models
ollama pull bge-m3
ollama pull e5-mistral-7b
ollama pull qwen3-vl-embedding-8b
```