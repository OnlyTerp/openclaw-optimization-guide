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
