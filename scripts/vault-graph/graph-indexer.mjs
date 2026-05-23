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

const WORKSPACE = resolve(process.env.OPENCLAW_WORKSPACE || '.');
const VAULT_DIR = join(WORKSPACE, 'vault');
const MEMORY_DIR = join(WORKSPACE, 'memory');
const OUTPUT_FILE = join(VAULT_DIR, '06_system', 'graph-index.json');

const ROOT_FILES = [
  'MEMORY.md', 'SOUL.md', 'AGENTS.md', 'TOOLS.md', 'USER.md', 'IDENTITY.md'
].map(f => join(WORKSPACE, f));

const WIKI_LINK_RE = /\[\[([^\]|]+?)(?:\|[^\]]+)?\]\]/g;

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
      console.error(`Warning: error processing ${fp}: ${err.message}`);
    }
  }
  return graph;
}

function printStats(graph) {
  const entries = Object.entries(graph);
  let totalLinks = 0;
  for (const [, node] of entries) totalLinks += node.linksTo.length;

  const connectivity = entries.map(([key, node]) => ({
    key, title: node.title,
    total: node.linksTo.length + node.linkedFrom.length
  })).sort((a, b) => b.total - a.total);

  const orphans = connectivity.filter(n => n.total === 0);

  console.log(`\nIndexed: ${entries.length} files | ${totalLinks} wiki-links | ${entries.length - orphans.length} connected | ${orphans.length} orphans\n`);
  console.log('Top 10 most connected:');
  for (const n of connectivity.slice(0, 10)) {
    if (n.total === 0) break;
    console.log(`  ${n.total.toString().padStart(3)} links | ${n.title}`);
  }
}

async function main() {
  const filePaths = await discoverFiles();
  console.log(`Found ${filePaths.length} markdown files`);
  const graph = await buildGraph(filePaths);
  await mkdir(join(VAULT_DIR, '06_system'), { recursive: true });
  await writeFile(OUTPUT_FILE, JSON.stringify(graph, null, 2), 'utf-8');
  console.log(`Saved to vault/06_system/graph-index.json`);
  printStats(graph);
}

main().catch(err => { console.error('Error:', err); process.exit(1); });
