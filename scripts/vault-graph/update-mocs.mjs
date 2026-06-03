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
