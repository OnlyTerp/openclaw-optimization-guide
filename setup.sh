#!/bin/bash
# OpenClaw Optimization Setup Script
# Run: bash setup.sh
# Or:  chmod +x setup.sh && ./setup.sh

set -e

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
CONFIG="$HOME/.openclaw/openclaw.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "  OpenClaw Optimization Setup"
echo "  By Terp AI Labs (@OnlyTerp)"
echo "=========================================="
echo ""

# Step 1: Backup
echo "[1/5] Backing up config..."
if [ -f "$CONFIG" ]; then
    cp "$CONFIG" "$CONFIG.bak"
    echo "  ✓ Backed up to $CONFIG.bak"
else
    echo "  ⚠ No config found at $CONFIG — skipping backup"
fi

# Step 2: Create vault structure
echo "[2/5] Creating vault directory structure..."
mkdir -p "$WORKSPACE/vault/projects"
mkdir -p "$WORKSPACE/vault/people"
mkdir -p "$WORKSPACE/vault/decisions"
mkdir -p "$WORKSPACE/vault/lessons"
mkdir -p "$WORKSPACE/vault/reference"
mkdir -p "$WORKSPACE/vault/research"
mkdir -p "$WORKSPACE/memory"
echo "  ✓ vault/ and memory/ directories created"

# Step 3: Install template files (only if they don't exist or are larger than target)
echo "[3/5] Installing optimized workspace files..."

install_template() {
    local target="$WORKSPACE/$1"
    local source="$SCRIPT_DIR/templates/$1"
    local max_kb=$2
    
    if [ ! -f "$target" ]; then
        cp "$source" "$target"
        echo "  ✓ Created $1"
    else
        local size=$(wc -c < "$target" 2>/dev/null || echo 0)
        local max_bytes=$((max_kb * 1024))
        if [ "$size" -gt "$max_bytes" ]; then
            # Backup existing, install template
            cp "$target" "$target.pre-optimize"
            cp "$source" "$target"
            echo "  ✓ Optimized $1 (was $(($size/1024))KB, backed up to $1.pre-optimize)"
        else
            echo "  ○ $1 already under ${max_kb}KB — skipping"
        fi
    fi
}

install_template "SOUL.md" 2
install_template "AGENTS.md" 3
install_template "MEMORY.md" 4
install_template "TOOLS.md" 2

# Step 4: Install Ollama + embedding model
echo "[4/5] Setting up Ollama + nomic-embed-text..."

if command -v ollama &> /dev/null; then
    echo "  ✓ Ollama already installed"
else
    echo "  Installing Ollama..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install ollama 2>/dev/null || curl -fsSL https://ollama.com/install.sh | sh
    else
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    echo "  ✓ Ollama installed"
fi

# Pull embedding model
if ollama list 2>/dev/null | grep -q "nomic-embed-text"; then
    echo "  ✓ nomic-embed-text already available"
else
    echo "  Pulling nomic-embed-text (300MB)..."
    ollama pull nomic-embed-text
    echo "  ✓ nomic-embed-text ready"
fi

# Step 5: Verify
echo "[5/5] Verifying setup..."
echo ""

total_size=0
for f in SOUL.md AGENTS.md MEMORY.md TOOLS.md; do
    if [ -f "$WORKSPACE/$f" ]; then
        size=$(wc -c < "$WORKSPACE/$f")
        total_size=$((total_size + size))
        echo "  $f: ${size} bytes"
    fi
done
echo "  ─────────────────"
echo "  Total context: ${total_size} bytes ($((total_size/1024))KB)"
echo ""

if [ "$total_size" -lt 8192 ]; then
    echo "  ✓ Context under 8KB — you're optimized!"
else
    echo "  ⚠ Context over 8KB — consider trimming further"
fi

if [ -d "$WORKSPACE/vault" ]; then
    echo "  ✓ vault/ structure ready"
fi

if command -v ollama &> /dev/null; then
    echo "  ✓ Ollama installed"
fi

echo ""
echo "=========================================="
echo "  Setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Restart gateway: openclaw gateway stop && openclaw gateway start"
echo "  2. Move detailed docs from MEMORY.md to vault/ files"
echo "  3. Test: ask your bot about a past project"
echo "=========================================="
