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
