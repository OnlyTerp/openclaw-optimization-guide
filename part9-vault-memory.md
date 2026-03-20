
---

## Part 9: Vault Memory System (Stop Losing Knowledge Between Sessions)

Part 4 gave you memory. It works — `memory_search()` is fast, local, and free. But after a few months of daily use, you'll notice something: **your agent is getting dumber, not smarter.**

Here's what happened to us: 358 memory files. 100MB+ of accumulated knowledge. Vector search returning irrelevant results because every query matches 15 files about slightly different things. Date-named files like `2026-02-27-cerebras-session.md` that tell you nothing from the filename. Research conclusions from a 2-hour session — gone, because nobody saved them to memory. The agent starts every session fresh, reads MEMORY.md, and has zero idea what happened yesterday.

**The more you teach it, the worse it gets.** That's the sign your memory architecture is broken.

### Why Flat Files + Vector Search Breaks Down

Vector search finds what's *similar*. That's the problem. Ask "what do we know about God Mode?" and you get 8 files that all mention Cerebras somewhere. None of them give you the full picture because the full picture is spread across 12 files that vector search doesn't know are related.

The failure modes:

| Problem | What Happens | Real Example |
|---------|-------------|--------------|
| **Date-named files** | Filename tells you nothing | `2026-03-19.md` — what's in it? Who knows |
| **No connections** | Related files don't know about each other | God Mode research in 3 files, none linked |
| **Bloat pollutes results** | Generic knowledge drowns specific insights | "What's our memory architecture?" returns 15 partial matches |
| **Session amnesia** | Agent starts fresh every time | "We discussed this yesterday" — no it didn't |
| **MEMORY.md overflow** | Index file grows past injection limit | MEMORY.md hit 20K, context truncated on every message |
| **Vector search ceiling** | Similarity ≠ understanding | Finds files that mention the word, not files that answer the question |

The fix isn't better embeddings or a fancier vector database. **The fix is structure.**

### The Solution: Vault Architecture

Instead of a flat `memory/` folder with hundreds of date-named files, you build an Obsidian-inspired linked knowledge vault. The key ideas:

1. **Notes are named as claims, not topics** — the filename IS the knowledge
2. **Topic pages (MOCs) link related notes** — one page gives you the full picture
3. **Wiki-links create a traversable graph** — the agent follows connections, not similarity
4. **Agent Notes provide cross-session breadcrumbs** — the next session picks up where this one left off

Here's the folder structure:

```
vault/
  00_inbox/      ← Raw captures. Dump it here, structure later
  01_thinking/   ← MOCs (Maps of Content) + synthesized notes
  02_reference/  ← External knowledge, tool docs, API references
  03_creating/   ← Content drafts in progress
  04_published/  ← Finished work (includes metadata: date, platform, link)
  05_archive/    ← Inactive content. Never delete, always archive
  06_system/     ← Templates, vault philosophy, graph index
```

#### Claim-Named Notes

This is the single biggest upgrade. Stop naming files by date. Name them by what they claim.

```
BAD:                                          GOOD:
2026-03-19.md                                 nemotron-mamba-wont-train-on-windows.md
session-notes.md                              memory-is-the-bottleneck.md
training-stuff.md                             local-models-are-the-fast-layer.md
cerebras-research.md                          god-mode-is-cerebras-plus-orchestration.md
```

A claim-name forces clarity. If you can't name a note as a claim, you haven't thought about it enough. Put it in `00_inbox/` and come back when you can name it.

The agent reads filenames before reading content. When every filename is a claim, scanning a folder gives the agent a map of everything you know — without opening a single file.

#### MOCs — Maps of Content

A MOC is a topic page that connects related notes with `[[wiki-links]]`. It's the difference between searching for knowledge and navigating to it.

Here's what a real MOC looks like:

```markdown
# Memory Is The Bottleneck

The agent's intelligence isn't the limiting factor — memory is.
Every session starts fresh. The files are the memory.

## Key Facts

- **358 memory files** in memory/, mostly date-named
- **Vector search** (nomic-embed-text, 45ms, $0) works but finds similar, not connected
- **MEMORY.md** must stay under 5K — it's injected on every message
- **The more you teach, the dumber it gets** — MEMORY.md overflow truncated context

## Connected Topics

- [[vault/decisions/memory-architecture.md]] — migration to tiered memory
- [[vault/research/rag-injection-research.md]] — RAG research
- [[vault/projects/reasoning-traces.md]] — 935K reasoning traces as searchable memory

## The Problem Chain

1. Session starts fresh → agent reads MEMORY.md
2. MEMORY.md too large → truncation on every message
3. Knowledge in wrong place → vector search can't find it
4. Session data not saved → research lost forever
5. Vector search limited → finds similar, not connected

## Agent Notes

- [x] Vault restructure completed — 8 MOCs + philosophy doc
- [ ] Every session MUST save knowledge to memory
- [ ] Consider building wiki-link adjacency index
```

The `## Agent Notes` section is the cross-session breadcrumb trail. When the agent touches a topic, it updates these notes. The next session reads them and picks up exactly where the last one stopped.

#### The Vault Philosophy Document

This is the document that teaches your agent HOW to use the vault. Put it in `vault/06_system/vault-philosophy.md`. It's the operating manual — the agent reads it and follows the rules.

Create it with these core principles:

```markdown
# Vault Philosophy — How This Agent Thinks

## 1. The Network Is The Knowledge
No single note is the answer. The answer is the path through connected notes.
Never write a note without linking it.

## 2. Notes Are Named As Claims, Not Topics
Bad: `local-models.md` — what about them?
Good: `local-models-are-the-fast-layer.md` — now you know the argument.

## 3. Links Are Woven Into Sentences, Not Footnotes
Bad: See also: [1] [2] [3]
Good: God Mode wraps [[god-mode-is-cerebras-plus-orchestration]] around Cerebras,
      routing through the [[the-hybrid-proxy-routes-by-complexity]].

## 4. Agent Orients Before Acting
Before answering, follow: scan MOCs → read relevant MOC → follow links → respond.
Skipping orientation = giving wrong answers from stale memory.

## 5. Agent Leaves Breadcrumbs
After every session, update MOC "Agent Notes" with what was done, discovered,
and what's still open. This is how continuity works.

## 6. Capture First, Structure Later
Ideas die between "I should write this down" and "I should organize it perfectly."
Dump in 00_inbox/ now. Structure later.
```

This document is not for you — it's for the agent. You're programming behavior through prose. The agent reads this philosophy and internalizes the rules. You'll see the difference immediately: it starts linking notes, updating Agent Notes sections, and navigating the vault instead of searching blindly.

### The Graph: Wiki-Link Indexer

MOCs and wiki-links create a graph, but the agent can't traverse it without tooling. You need two scripts: one that builds the graph, one that searches it.

#### graph-indexer.mjs

This script scans every `.md` file across your vault, memory, and workspace root. It parses `[[wiki-links]]`, resolves them to actual files, and builds a JSON adjacency graph.

Save this to `scripts/vault-graph/graph-indexer.mjs`:

```javascript
#!/usr/bin/env node
/**
 * graph-indexer.mjs — Wiki-Link Graph Indexer for OpenClaw Vault
 *
 * Scans vault/ (recursive), memory/ (top-level), and root .md files.
 * Parses [[wiki-links]], builds adjacency graph, saves JSON index.
 *
 * Zero npm dependencies. ES module.
 *
 * Usage: node scripts/vault-graph/graph-indexer.mjs
 * Output: vault/06_system/graph-index.json + stats
 */

import { readdir, readFile, stat, writeFile, mkdir } from 'node:fs/promises';
import { join, basename, relative, extname, resolve } from 'node:path';
import { existsSync } from 'node:fs';

// ── Configuration (edit these to match your workspace) ─────────────────────

const WORKSPACE = resolve(process.env.OPENCLAW_WORKSPACE || '.');
const VAULT_DIR = join(WORKSPACE, 'vault');
const MEMORY_DIR = join(WORKSPACE, 'memory');
const OUTPUT_FILE = join(VAULT_DIR, '06_system', 'graph-index.json');

const ROOT_FILES = [
  'MEMORY.md', 'SOUL.md', 'AGENTS.md', 'TOOLS.md', 'USER.md', 'IDENTITY.md'
].map(f => join(WORKSPACE, f));

const WIKI_LINK_RE = /\[\[([^\]|]+?)(?:\|[^\]]+)?\]\]/g;

// ── File Discovery ─────────────────────────────────────────────────────────

async function collectMdFilesRecursive(dir) {
  const results = [];
  if (!existsSync(dir)) return results;
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name.startsWith('.')) continue;
      results.push(...await collectMdFilesRecursive(fullPath));
    } else if (entry.isFile() && extname(entry.name).toLowerCase() === '.md') {
      results.push(fullPath);
    }
  }
  return results;
}

async function collectMemoryTopLevel() {
  const results = [];
  if (!existsSync(MEMORY_DIR)) return results;
  const entries = await readdir(MEMORY_DIR, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isFile() && extname(entry.name).toLowerCase() === '.md') {
      results.push(join(MEMORY_DIR, entry.name));
    }
  }
  return results;
}

async function discoverFiles() {
  const [vaultFiles, memoryFiles] = await Promise.all([
    collectMdFilesRecursive(VAULT_DIR),
    collectMemoryTopLevel()
  ]);
  const rootFiles = ROOT_FILES.filter(f => existsSync(f));
  return [...vaultFiles, ...memoryFiles, ...rootFiles];
}

// ── Parsing ────────────────────────────────────────────────────────────────

function extractTitle(content, filePath) {
  const match = content.match(/^#{1,6}\s+(.+)$/m);
  return match ? match[1].trim() : basename(filePath, '.md');
}

function extractWikiLinks(content) {
  const links = new Set();
  let match;
  WIKI_LINK_RE.lastIndex = 0;
  while ((match = WIKI_LINK_RE.exec(content)) !== null) {
    const target = match[1].trim();
    if (target) links.add(target);
  }
  return [...links];
}

// ── Link Resolution ────────────────────────────────────────────────────────

function buildLookupMap(filePaths) {
  const lookup = new Map();
  for (const fp of filePaths) {
    const rel = relative(WORKSPACE, fp).replace(/\\/g, '/');
    const name = basename(fp, '.md');
    const keys = [
      name.toLowerCase(),
      basename(fp).toLowerCase(),
      rel.toLowerCase(),
      rel.replace(/\.md$/i, '').toLowerCase(),
    ];
    for (const key of keys) {
      if (!lookup.has(key)) lookup.set(key, []);
      lookup.get(key).push(fp);
    }
  }
  return lookup;
}

function resolveLink(rawTarget, lookupMap) {
  const normalized = rawTarget.replace(/\\/g, '/').trim().toLowerCase();
  const withoutExt = normalized.replace(/\.md$/i, '');
  for (const key of [withoutExt, normalized, withoutExt + '.md']) {
    const matches = lookupMap.get(key);
    if (matches?.length > 0) return matches[0];
  }
  for (const [key, paths] of lookupMap.entries()) {
    if (key.endsWith('/' + withoutExt) || key.endsWith('/' + normalized)) {
      return paths[0];
    }
  }
  return null;
}

// ── Graph Building ─────────────────────────────────────────────────────────

async function buildGraph(filePaths) {
  const lookupMap = buildLookupMap(filePaths);
  const graph = {};

  for (const fp of filePaths) {
    const key = relative(WORKSPACE, fp).replace(/\\/g, '/');
    graph[key] = { linksTo: [], linkedFrom: [], title: '', lastModified: '', path: fp.replace(/\\/g, '/') };
  }

  for (const fp of filePaths) {
    const key = relative(WORKSPACE, fp).replace(/\\/g, '/');
    try {
      const content = await readFile(fp, 'utf-8');
      const fileStat = await stat(fp);
      graph[key].title = extractTitle(content, fp);
      graph[key].lastModified = fileStat.mtime.toISOString();

      for (const rawLink of extractWikiLinks(content)) {
        const resolvedPath = resolveLink(rawLink, lookupMap);
        if (resolvedPath) {
          const targetKey = relative(WORKSPACE, resolvedPath).replace(/\\/g, '/');
          if (!graph[key].linksTo.includes(targetKey)) graph[key].linksTo.push(targetKey);
          if (graph[targetKey] && !graph[targetKey].linkedFrom.includes(key))
            graph[targetKey].linkedFrom.push(key);
        }
      }
    } catch (err) {
      console.error(`⚠ Error processing ${fp}: ${err.message}`);
    }
  }
  return graph;
}

// ── Stats ──────────────────────────────────────────────────────────────────

function printStats(graph) {
  const entries = Object.entries(graph);
  let totalLinks = 0;
  for (const [, node] of entries) totalLinks += node.linksTo.length;

  const connectivity = entries.map(([key, node]) => ({
    key, title: node.title,
    total: node.linksTo.length + node.linkedFrom.length
  })).sort((a, b) => b.total - a.total);

  const orphans = connectivity.filter(n => n.total === 0);

  console.log(`\n📊 Indexed: ${entries.length} files | ${totalLinks} wiki-links | ${entries.length - orphans.length} connected | ${orphans.length} orphans\n`);
  console.log('Top 10 most connected:');
  for (const n of connectivity.slice(0, 10)) {
    if (n.total === 0) break;
    console.log(`  ${n.total.toString().padStart(3)} links │ ${n.title}`);
  }
}

// ── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const filePaths = await discoverFiles();
  console.log(`🔍 Found ${filePaths.length} markdown files`);
  const graph = await buildGraph(filePaths);
  await mkdir(join(VAULT_DIR, '06_system'), { recursive: true });
  await writeFile(OUTPUT_FILE, JSON.stringify(graph, null, 2), 'utf-8');
  console.log(`💾 Saved to vault/06_system/graph-index.json`);
  printStats(graph);
}

main().catch(err => { console.error('❌', err); process.exit(1); });
```

Run it:

```bash
node scripts/vault-graph/graph-indexer.mjs
```

Output looks like this:

```
🔍 Found 326 markdown files
💾 Saved to vault/06_system/graph-index.json

📊 Indexed: 326 files | 71 wiki-links | 47 connected | 279 orphans

Top 10 most connected:
   18 links │ God Mode Is Cerebras Plus Orchestration
   12 links │ Memory Is The Bottleneck
   10 links │ Training Your Own Model Changes Everything
    8 links │ The Hybrid Proxy Routes By Complexity
    7 links │ Local Models Are The Fast Layer
    6 links │ OpenClaw Is An Orchestrator Not A Worker
    ...
```

The graph index is a JSON file — every node lists its outgoing links, incoming links, title, and path. This is the map your agent navigates.

#### graph-search.mjs

This is the CLI your agent uses to traverse the graph. Give it a search term and it finds matching files, their direct connections, and 2nd-degree connections (files connected through direct connections).

Save this to `scripts/vault-graph/graph-search.mjs`:

```javascript
#!/usr/bin/env node
/**
 * graph-search.mjs — Traverse the wiki-link graph
 *
 * Usage: node scripts/vault-graph/graph-search.mjs "search term"
 */

import { readFile } from 'node:fs/promises';
import { resolve, basename } from 'node:path';
import { existsSync } from 'node:fs';

const WORKSPACE = resolve(process.env.OPENCLAW_WORKSPACE || '.');
const INDEX_FILE = resolve(WORKSPACE, 'vault/06_system/graph-index.json');

async function loadGraph() {
  if (!existsSync(INDEX_FILE)) {
    console.error('❌ Run graph-indexer.mjs first');
    process.exit(1);
  }
  return JSON.parse(await readFile(INDEX_FILE, 'utf-8'));
}

function findMatches(graph, term) {
  const t = term.toLowerCase();
  const matches = [];
  for (const [key, node] of Object.entries(graph)) {
    const keyL = key.toLowerCase(), nameL = basename(key, '.md').toLowerCase();
    const titleL = (node.title || '').toLowerCase();
    let score = 0;
    if (keyL === t || keyL === t + '.md') score = 100;
    else if (nameL === t) score = 90;
    else if (keyL.includes(t)) score = 60;
    else if (titleL.includes(t)) score = 40;
    if (score) matches.push({ key, node, score });
  }
  return matches.sort((a, b) => b.score - a.score);
}

function getSecondDegree(graph, nodeKey, directKeys) {
  const second = new Map();
  const skip = new Set([nodeKey, ...directKeys]);
  for (const dk of directKeys) {
    const dn = graph[dk];
    if (!dn) continue;
    for (const t of [...dn.linksTo, ...dn.linkedFrom]) {
      if (!skip.has(t)) second.set(t, dk);
    }
  }
  return second;
}

async function main() {
  const term = process.argv[2];
  if (!term) { console.log('Usage: node graph-search.mjs "term"'); process.exit(0); }
  const graph = await loadGraph();
  const matches = findMatches(graph, term);

  if (!matches.length) { console.log(`No matches for "${term}"`); return; }

  for (const { key, node } of matches.slice(0, 5)) {
    console.log(`\n📄 ${node.title || key}`);
    console.log(`   ${key}`);
    if (node.linksTo.length) {
      console.log(`   📤 Links to:`);
      for (const t of node.linksTo) console.log(`      → ${graph[t]?.title || t}`);
    }
    if (node.linkedFrom.length) {
      console.log(`   📥 Linked from:`);
      for (const s of node.linkedFrom) console.log(`      ← ${graph[s]?.title || s}`);
    }
    const directKeys = [...node.linksTo, ...node.linkedFrom];
    const second = getSecondDegree(graph, key, directKeys);
    if (second.size) {
      console.log(`   🌐 2nd degree (${second.size}):`);
      for (const [sk, via] of [...second.entries()].slice(0, 10)) {
        console.log(`      ↔ ${graph[sk]?.title || sk} (via ${graph[via]?.title || via})`);
      }
    }
  }
}

main().catch(console.error);
```

Usage:

```bash
node scripts/vault-graph/graph-search.mjs "memory"
```

```
📄 Memory Is The Bottleneck
   vault/01_thinking/memory-is-the-bottleneck.md
   📤 Links to:
      → memory-architecture
      → memory-system-upgrade-20260312
      → rag-injection-research
      → reasoning-traces
   📥 Linked from:
      → God Mode Is Cerebras Plus Orchestration
      → Training Your Own Model Changes Everything
   🌐 2nd degree (8):
      ↔ Local Models Are The Fast Layer (via God Mode Is Cerebras Plus Orchestration)
      ↔ Cerebras Agent (via God Mode Is Cerebras Plus Orchestration)
      ...
```

#### Why Graph > Vector Search for Connected Knowledge

Vector search answers: "What files are **similar** to this query?"

Graph search answers: "What files are **connected** to this topic?"

These are fundamentally different questions. When you ask "what do we know about God Mode?", you don't want 8 files that all mention Cerebras somewhere. You want the God Mode MOC, the 6 files it links to, and the 12 files connected through those links. That's graph traversal, not similarity matching.

Vector search is still useful — it's great for finding things you don't know exist. But once you have structured knowledge, graph traversal finds the right answer faster and more reliably. Use both:

```
memory_search("topic")  → Find files you didn't know were relevant
graph-search "topic"    → Navigate files you know are connected
```

### Auto-Capture: Automated Session Knowledge Capture

Knowledge dies in the gap between "we figured this out" and "somebody wrote it down." Auto-capture scripts close that gap.

#### auto-capture.mjs

Creates claim-named notes in `00_inbox/`, auto-detects related MOCs, and links them bidirectionally.

Save to `scripts/vault-graph/auto-capture.mjs`:

```javascript
#!/usr/bin/env node
/**
 * Auto-Capture: Converts insights into claim-named vault notes.
 *
 * Usage:
 *   node auto-capture.mjs --claim "nemotron mamba wont train on windows" --body "details..."
 *   node auto-capture.mjs --file summary.txt
 *   echo "insight text" | node auto-capture.mjs
 */

import fs from 'fs';
import path from 'path';

const VAULT = process.env.OPENCLAW_WORKSPACE
  ? path.join(process.env.OPENCLAW_WORKSPACE, 'vault')
  : path.resolve('vault');
const INBOX = path.join(VAULT, '00_inbox');
const THINKING = path.join(VAULT, '01_thinking');

function toClaimName(text) {
  let claim = text.split(/[.!?\n]/)[0].trim();
  if (claim.length > 80) claim = claim.substring(0, 80);
  return claim.toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .substring(0, 60) + '.md';
}

function findRelatedMOCs(text) {
  if (!fs.existsSync(THINKING)) return [];
  const mocs = fs.readdirSync(THINKING).filter(f => f.endsWith('.md') && f !== 'README.md');
  const textLower = text.toLowerCase();
  return mocs.filter(moc => {
    const keywords = moc.replace('.md', '').split('-').filter(w => w.length > 3);
    return keywords.filter(kw => textLower.includes(kw)).length >= 2;
  }).map(m => m.replace('.md', ''));
}

function buildNote(claim, body, relatedMOCs) {
  const date = new Date().toISOString().split('T')[0];
  let note = `# ${claim}\n\n## Key Facts\n\n${body}\n\n`;
  if (relatedMOCs.length > 0) {
    note += `## Connected Topics\n\n`;
    for (const moc of relatedMOCs) note += `- [[${moc}]]\n`;
    note += `\n`;
  }
  note += `## Agent Notes\n\n- [ ] Review and verify this capture\n`;
  note += `- [ ] Link to additional related notes\n`;
  note += `- [ ] Move from inbox to appropriate vault folder\n`;
  note += `\n_Captured: ${date}_\n`;
  return note;
}

function updateMOCs(filename, relatedMOCs) {
  const linkName = filename.replace('.md', '');
  for (const moc of relatedMOCs) {
    const mocPath = path.join(THINKING, moc + '.md');
    if (!fs.existsSync(mocPath)) continue;
    let content = fs.readFileSync(mocPath, 'utf8');
    if (!content.includes(`[[${linkName}]]`)) {
      const idx = content.indexOf('## Agent Notes');
      if (idx !== -1) {
        const insertPoint = content.indexOf('\n', idx) + 1;
        content = content.substring(0, insertPoint)
          + `\n- [ ] New capture linked: [[${linkName}]]\n`
          + content.substring(insertPoint);
        fs.writeFileSync(mocPath, content, 'utf8');
        console.log(`  Updated MOC: ${moc}.md`);
      }
    }
  }
}

async function main() {
  const args = process.argv.slice(2);
  let claim = '', body = '';
  if (args.includes('--claim')) claim = args[args.indexOf('--claim') + 1] || '';
  if (args.includes('--body')) body = args[args.indexOf('--body') + 1] || '';
  if (args.includes('--file')) {
    const f = args[args.indexOf('--file') + 1];
    if (f && fs.existsSync(f)) { body = fs.readFileSync(f, 'utf8'); if (!claim) claim = body.split('\n')[0]; }
  }
  if (!claim && !body) {
    console.log('Usage: node auto-capture.mjs --claim "insight" --body "details..."');
    process.exit(1);
  }
  const filename = toClaimName(claim);
  const filepath = path.join(INBOX, filename);
  const relatedMOCs = findRelatedMOCs(claim + ' ' + body);
  if (!fs.existsSync(INBOX)) fs.mkdirSync(INBOX, { recursive: true });
  fs.writeFileSync(filepath, buildNote(claim, body, relatedMOCs), 'utf8');
  console.log(`✅ Captured: ${filename}`);
  if (relatedMOCs.length > 0) {
    console.log(`   Related MOCs: ${relatedMOCs.join(', ')}`);
    updateMOCs(filename, relatedMOCs);
  }
}

main().catch(console.error);
```

Usage:

```bash
# Agent discovers something mid-session
node scripts/vault-graph/auto-capture.mjs \
  --claim "nemotron mamba wont train on windows" \
  --body "The Mamba architecture requires triton which is Linux-only. WSL works but native Windows fails with CUDA errors."
```

```
✅ Captured: nemotron-mamba-wont-train-on-windows.md
   Related MOCs: training-your-own-model-changes-everything
   Updated MOC: training-your-own-model-changes-everything.md
```

The note lands in `00_inbox/` with wiki-links to related MOCs. The MOCs get updated with a backlink. The graph grows automatically.

#### process-inbox.mjs

Reviews inbox notes and suggests where to file them. With `--auto`, moves them automatically.

Save to `scripts/vault-graph/process-inbox.mjs`:

```javascript
#!/usr/bin/env node
/**
 * Process Inbox: Scans vault/00_inbox/ and suggests filing locations.
 *
 * Usage:
 *   node process-inbox.mjs          # report only
 *   node process-inbox.mjs --auto   # auto-move files
 */

import fs from 'fs';
import path from 'path';

const VAULT = process.env.OPENCLAW_WORKSPACE
  ? path.join(process.env.OPENCLAW_WORKSPACE, 'vault')
  : path.resolve('vault');
const INBOX = path.join(VAULT, '00_inbox');

function classifyNote(filename, content) {
  const lower = content.toLowerCase();
  const wikiLinks = (content.match(/\[\[/g) || []).length;
  if (wikiLinks >= 3 || lower.includes('## agent notes')) return '01_thinking';
  if (lower.includes('api') || lower.includes('documentation') || lower.includes('reference')) return '02_reference';
  if (lower.includes('draft') || lower.includes('script') || lower.includes('outline')) return '03_creating';
  return '01_thinking';
}

function main() {
  const autoMove = process.argv.includes('--auto');
  if (!fs.existsSync(INBOX)) { console.log('📭 Inbox empty.'); return; }
  const files = fs.readdirSync(INBOX).filter(f => f.endsWith('.md') && f !== 'README.md');
  if (!files.length) { console.log('📭 Inbox empty.'); return; }

  console.log(`📬 ${files.length} notes to process:\n`);
  for (const file of files) {
    const content = fs.readFileSync(path.join(INBOX, file), 'utf8');
    const dest = classifyNote(file, content);
    console.log(`  ${file} → vault/${dest}/`);
    if (autoMove) {
      const destDir = path.join(VAULT, dest);
      if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });
      fs.renameSync(path.join(INBOX, file), path.join(destDir, file));
      console.log(`  ✅ Moved!`);
    }
  }
  if (!autoMove && files.length) console.log(`\nRun with --auto to move files.`);
}

main();
```

#### update-mocs.mjs

Health check for your MOCs. Finds broken wiki-links, stale completed items, and orphaned notes.

Save to `scripts/vault-graph/update-mocs.mjs`:

```javascript
#!/usr/bin/env node
/**
 * MOC Health Check: Validates wiki-links and finds stale items.
 *
 * Usage: node update-mocs.mjs
 */

import fs from 'fs';
import path from 'path';

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || path.resolve('.');
const VAULT = path.join(WORKSPACE, 'vault');
const MEMORY = path.join(WORKSPACE, 'memory');
const THINKING = path.join(VAULT, '01_thinking');

function collectFiles(dir, recursive = true) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory() && recursive) results.push(...collectFiles(full));
    else if (entry.name.endsWith('.md')) results.push(full);
  }
  return results;
}

function buildFileIndex() {
  const index = new Map();
  const allFiles = [
    ...collectFiles(VAULT),
    ...collectFiles(MEMORY, false),
    ...['MEMORY.md', 'SOUL.md', 'AGENTS.md', 'TOOLS.md', 'USER.md', 'IDENTITY.md']
      .map(f => path.join(WORKSPACE, f)).filter(f => fs.existsSync(f)),
  ];
  for (const f of allFiles) {
    const bn = path.basename(f, '.md').toLowerCase();
    const rel = path.relative(WORKSPACE, f).replace(/\\/g, '/');
    index.set(bn, f);
    index.set(rel.toLowerCase(), f);
    index.set(rel.replace(/\.md$/i, '').toLowerCase(), f);
  }
  return index;
}

function main() {
  if (!fs.existsSync(THINKING)) { console.log('No MOCs found.'); return; }
  const fileIndex = buildFileIndex();
  const mocs = fs.readdirSync(THINKING).filter(f => f.endsWith('.md') && f !== 'README.md');

  console.log(`🔍 Checking ${mocs.length} MOCs\n`);
  let totalLinks = 0, brokenLinks = 0;

  for (const moc of mocs) {
    const content = fs.readFileSync(path.join(THINKING, moc), 'utf8');
    const links = [...content.matchAll(/\[\[([^\]|]+)/g)].map(m => m[1].trim());
    const broken = links.filter(l => {
      const k = l.toLowerCase().replace(/\.md$/i, '');
      return !fileIndex.has(k) && !fileIndex.has(k.split('/').pop());
    });
    totalLinks += links.length;
    brokenLinks += broken.length;
    if (broken.length) {
      console.log(`📄 ${moc}`);
      for (const b of broken) console.log(`   ❌ [[${b}]] → not found`);
    }
  }
  console.log(`\n${mocs.length} MOCs | ${totalLinks} links | ${brokenLinks} broken`);
}

main();
```

Run the health check periodically:

```bash
node scripts/vault-graph/update-mocs.mjs
```

```
🔍 Checking 8 MOCs

8 MOCs | 71 links | 0 broken
```

Zero broken links means your knowledge graph is healthy. Every wiki-link points to a real file.

### The Orientation Protocol: How the Agent Uses the Vault

The tools are useless if the agent doesn't know when to use them. Add this to your `AGENTS.md`:

```markdown
## Vault Orientation Protocol
On session start (after reading bootstrap files):
1. Scan `vault/01_thinking/` — read MOC filenames (they're claim-named, titles tell you the topic)
2. On first user message: if it relates to an existing MOC topic, read that MOC before responding
3. Follow [[wiki-links]] from the MOC to build deeper context if needed
4. After session work: update relevant MOC "Agent Notes" sections with what was done/discovered
5. For new knowledge: write claim-named notes to `vault/00_inbox/` — NOT date-named files

Naming convention for new notes:
- BAD: `2026-03-20.md`, `session-notes.md`, `training-stuff.md`
- GOOD: `nemotron-mamba-wont-train-on-windows.md`, `mimo-v2-pro-is-free-and-good.md`
- The filename IS the knowledge. Name it as a claim or insight.
```

This creates a cycle:

```
Session Start                              Session End
     │                                          │
     ▼                                          ▼
Scan MOC titles                     Update MOC Agent Notes
     │                                          │
     ▼                                          ▼
Read relevant MOC              Capture new knowledge → 00_inbox/
     │                                          │
     ▼                                          ▼
Follow [[wiki-links]]              Run graph-indexer.mjs
     │                                          │
     ▼                                          ▼
Respond with full context          Graph updated for next session
```

**The agent orients before acting.** It never answers blind. It checks what it knows, follows the links, builds context, then responds. This is the difference between an agent that forgets everything and one that builds on its own knowledge.

The cross-session breadcrumbs in Agent Notes are the critical piece. Without them, every session starts from scratch. With them, the agent reads "last session we completed X and discovered Y — Z is still open" and picks up exactly where it left off.

### Kill the Bloat

If you've been running OpenClaw for a while, you probably have a `memory/knowledge-base/` directory full of generic reference material — things like "how to use Docker" or "Python best practices" or tool documentation the agent saved from the web. This stuff is killing your search results.

Move it all to `vault/05_archive/` or `vault/02_reference/`:

```bash
# Move the generic knowledge-base out of the primary search path
mv memory/knowledge-base vault/05_archive/knowledge-base

# Or if some of it is genuinely useful reference material
mv memory/knowledge-base/useful-docs vault/02_reference/
mv memory/knowledge-base vault/05_archive/knowledge-base
```

The goal: your primary search path (`memory/` top-level + `vault/01_thinking/`) should contain only YOUR knowledge — your projects, your decisions, your insights. Not generic documentation the agent could find with a web search.

**Before:** Vector search for "memory architecture" returns 15 results — 3 about your actual system, 12 generic articles about RAG pipelines.

**After:** Same search returns 3 results — all about your actual system. The generic stuff is archived where it won't pollute results but still exists if you specifically need it.

### Results

Here's the before/after from our production setup:

| Metric | Before (Flat Files) | After (Vault System) |
|--------|--------------------|--------------------|
| **Total files** | 358 flat files in memory/ | 326 indexed files across vault/ + memory/ |
| **File naming** | Date-named (`2026-03-19.md`) | Claim-named (`memory-is-the-bottleneck.md`) |
| **Search method** | Vector search only | Graph traversal + vector search |
| **Wiki-links** | 0 | 71 bidirectional links |
| **Topic pages** | 0 | 8 MOC pages in 01_thinking/ |
| **Broken links** | N/A | 0 (validated by update-mocs.mjs) |
| **Cross-session memory** | None — agent starts fresh | Agent Notes breadcrumbs in every MOC |
| **Knowledge capture** | Manual (usually forgotten) | auto-capture.mjs creates claim-named notes |
| **Session continuity** | "What did we do yesterday?" → blank stare | Reads Agent Notes → picks up where it left off |
| **Search relevance** | 15 partial matches, 3 useful | 3 connected results via graph traversal |

The total file count went down (358 → 326) because we archived bloat. The useful knowledge went up because it's structured and connected instead of scattered across date-named files.

The real number that matters: **0 lost sessions.** Every insight the agent discovers gets captured. Every topic has a MOC the next session can read. Every MOC has Agent Notes that say what happened and what's still open.

### Quick Setup

If you want to set this up from scratch:

**1. Create the vault structure:**
```bash
mkdir -p vault/{00_inbox,01_thinking,02_reference,03_creating,04_published,05_archive,06_system}
```

**2. Create your first MOC in `vault/01_thinking/`:**
Name it as a claim. Example: `my-project-needs-better-memory.md`. Follow the MOC template above — Key Facts, Connected Topics, Agent Notes.

**3. Create the vault philosophy document:**
Save the philosophy from earlier in this guide to `vault/06_system/vault-philosophy.md`.

**4. Set up the graph tools:**
```bash
mkdir -p scripts/vault-graph
# Save graph-indexer.mjs, graph-search.mjs, auto-capture.mjs,
# process-inbox.mjs, and update-mocs.mjs to scripts/vault-graph/
```

**5. Build the initial graph:**
```bash
node scripts/vault-graph/graph-indexer.mjs
```

**6. Add the orientation protocol to AGENTS.md** (copy the block from above).

**7. Move bloat to archive:**
```bash
# Move generic knowledge-base out of primary search path
mv memory/knowledge-base vault/05_archive/knowledge-base
```

**8. Rebuild the graph:**
```bash
node scripts/vault-graph/graph-indexer.mjs
```

That's it. Your agent now has structured memory, graph navigation, auto-capture, and cross-session continuity. It stops losing knowledge and starts building on it.

