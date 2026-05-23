#!/usr/bin/env node
/**
 * graph-search.mjs — Traverse the wiki-link graph
 *
 * Usage: node scripts/vault-graph/graph-search.mjs "search term"
 *
 * Finds matching files, their direct connections, and 2nd-degree connections.
 * Run graph-indexer.mjs first to build the index.
 */

import { readFile } from 'node:fs/promises';
import { resolve, basename } from 'node:path';
import { existsSync } from 'node:fs';

const WORKSPACE = resolve(process.env.OPENCLAW_WORKSPACE || '.');
const INDEX_FILE = resolve(WORKSPACE, 'vault/06_system/graph-index.json');

async function loadGraph() {
  if (!existsSync(INDEX_FILE)) {
    console.error('Run graph-indexer.mjs first to build the index.');
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
  if (!term) {
    console.log('Usage: node graph-search.mjs "search term"');
    process.exit(0);
  }
  const graph = await loadGraph();
  const matches = findMatches(graph, term);

  if (!matches.length) {
    console.log(`No matches for "${term}"`);
    return;
  }

  for (const { key, node } of matches.slice(0, 5)) {
    console.log(`\n${node.title || key}`);
    console.log(`   ${key}`);
    if (node.linksTo.length) {
      console.log(`   Links to:`);
      for (const t of node.linksTo) console.log(`      -> ${graph[t]?.title || t}`);
    }
    if (node.linkedFrom.length) {
      console.log(`   Linked from:`);
      for (const s of node.linkedFrom) console.log(`      <- ${graph[s]?.title || s}`);
    }
    const directKeys = [...node.linksTo, ...node.linkedFrom];
    const second = getSecondDegree(graph, key, directKeys);
    if (second.size) {
      console.log(`   2nd degree (${second.size}):`);
      for (const [sk, via] of [...second.entries()].slice(0, 10)) {
        console.log(`      <> ${graph[sk]?.title || sk} (via ${graph[via]?.title || via})`);
      }
    }
  }
}

main().catch(console.error);
