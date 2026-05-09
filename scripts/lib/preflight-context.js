#!/usr/bin/env node
// preflight-context.js — Memory Bridge preflight summarizer.
//
// Emits a single JSON document on stdout describing the target repo: identity,
// recent git log, TODO/FIXME counts, file-extension distribution, top-10
// largest tracked files, and standalone part*.md files.
//
// On any failure the script writes a structured JSON error to stderr and exits
// with code 1 — stdout is never partial output. Stdout is buffered until the
// full document is assembled.
//
// Usage:
//   node scripts/lib/preflight-context.js [repoPath]
//   PREFLIGHT_REPO=/path node scripts/lib/preflight-context.js
//
// No external dependencies. Node 24+.

"use strict";

const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const SCHEMA = "preflight-context/v1";
const GIT_LOG_LIMIT = 20;
const LARGEST_FILES_LIMIT = 10;

function fail(message, extra = {}) {
  const err = {
    schema: SCHEMA,
    error: true,
    message,
    ...extra,
  };
  process.stderr.write(JSON.stringify(err) + "\n");
  process.exit(1);
}

function resolveRepoPath() {
  const arg = process.argv[2];
  const env = process.env.PREFLIGHT_REPO;
  const candidate = arg || env || process.cwd();
  let abs;
  try {
    abs = fs.realpathSync(candidate);
  } catch (e) {
    fail("repo path does not exist", { repoPath: candidate, cause: String(e.message || e) });
  }
  let stat;
  try {
    stat = fs.statSync(abs);
  } catch (e) {
    fail("repo path is not accessible", { repoPath: abs, cause: String(e.message || e) });
  }
  if (!stat.isDirectory()) {
    fail("repo path is not a directory", { repoPath: abs });
  }
  if (!fs.existsSync(path.join(abs, ".git"))) {
    fail("repo path is not a git repository (no .git found)", { repoPath: abs });
  }
  return abs;
}

function git(repoPath, args) {
  return execFileSync("git", args, {
    cwd: repoPath,
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 64 * 1024 * 1024,
  });
}

function collectGitLog(repoPath) {
  // Use a delimiter unlikely to appear in commit messages.
  const sep = "";
  const fmt = ["%H", "%h", "%s", "%an", "%aI"].join(sep);
  let raw;
  try {
    raw = git(repoPath, ["log", `-${GIT_LOG_LIMIT}`, `--pretty=format:${fmt}`]);
  } catch (e) {
    // Empty repo (no commits yet) — treat as empty log instead of fatal.
    return [];
  }
  if (!raw) return [];
  return raw
    .split("\n")
    .filter((line) => line.length > 0)
    .map((line) => {
      const [sha, shortSha, subject, author, date] = line.split(sep);
      return { sha, shortSha, subject, author, date };
    });
}

function collectHeadAndBranch(repoPath) {
  let head = "";
  let branch = "";
  try {
    head = git(repoPath, ["rev-parse", "HEAD"]).trim();
  } catch {
    head = "";
  }
  try {
    branch = git(repoPath, ["rev-parse", "--abbrev-ref", "HEAD"]).trim();
  } catch {
    branch = "";
  }
  return { head, branch };
}

function collectTrackedFiles(repoPath) {
  // Use NUL-delimited output so paths with newlines are handled.
  const raw = git(repoPath, ["ls-files", "-z"]);
  if (!raw) return [];
  return raw.split("\0").filter((p) => p.length > 0);
}

function isProbablyText(buf) {
  // Quick heuristic: look for NUL bytes in first 8KB.
  const slice = buf.length > 8192 ? buf.subarray(0, 8192) : buf;
  for (let i = 0; i < slice.length; i++) {
    if (slice[i] === 0) return false;
  }
  return true;
}

function countTodoFixme(repoPath, files) {
  const todoRe = /\bTODO\b/g;
  const fixmeRe = /\bFIXME\b/g;
  let todo = 0;
  let fixme = 0;
  for (const rel of files) {
    const abs = path.join(repoPath, rel);
    let st;
    try {
      st = fs.statSync(abs);
    } catch {
      continue;
    }
    if (!st.isFile()) continue;
    // Skip very large files (>2MB) — unlikely to be source code worth scanning.
    if (st.size > 2 * 1024 * 1024) continue;
    let buf;
    try {
      buf = fs.readFileSync(abs);
    } catch {
      continue;
    }
    if (!isProbablyText(buf)) continue;
    const text = buf.toString("utf8");
    const t = text.match(todoRe);
    const f = text.match(fixmeRe);
    if (t) todo += t.length;
    if (f) fixme += f.length;
  }
  return { todo, fixme, total: todo + fixme };
}

function collectExtensionCounts(files) {
  const counts = {};
  for (const rel of files) {
    const base = path.basename(rel);
    let ext;
    if (base.startsWith(".") && base.indexOf(".", 1) === -1) {
      ext = base; // dotfile with no extension, e.g. .gitignore
    } else {
      ext = path.extname(base);
      if (!ext) ext = "<no-ext>";
    }
    counts[ext] = (counts[ext] || 0) + 1;
  }
  return counts;
}

function collectLargestFiles(repoPath, files) {
  const sized = [];
  for (const rel of files) {
    const abs = path.join(repoPath, rel);
    let st;
    try {
      st = fs.statSync(abs);
    } catch {
      continue;
    }
    if (!st.isFile()) continue;
    sized.push({ path: rel, sizeBytes: st.size });
  }
  sized.sort((a, b) => b.sizeBytes - a.sizeBytes);
  return sized.slice(0, LARGEST_FILES_LIMIT);
}

function collectPartFiles(repoPath) {
  let entries;
  try {
    entries = fs.readdirSync(repoPath, { withFileTypes: true });
  } catch (e) {
    fail("cannot read repo directory", { cause: String(e.message || e) });
  }
  const out = [];
  for (const ent of entries) {
    if (!ent.isFile()) continue;
    const name = ent.name;
    if (!/^part.*\.md$/i.test(name)) continue;
    const abs = path.join(repoPath, name);
    const st = fs.statSync(abs);
    let lineCount = 0;
    try {
      const text = fs.readFileSync(abs, "utf8");
      lineCount = text === "" ? 0 : text.split("\n").length;
    } catch {
      lineCount = 0;
    }
    out.push({ name, sizeBytes: st.size, lineCount });
  }
  out.sort((a, b) => a.name.localeCompare(b.name));
  return out;
}

function main() {
  const repoPath = resolveRepoPath();
  const files = collectTrackedFiles(repoPath);
  const { head, branch } = collectHeadAndBranch(repoPath);

  let totalSizeBytes = 0;
  for (const rel of files) {
    try {
      const st = fs.statSync(path.join(repoPath, rel));
      if (st.isFile()) totalSizeBytes += st.size;
    } catch {
      // skip
    }
  }

  const doc = {
    schema: SCHEMA,
    generatedAt: new Date().toISOString(),
    repo: {
      path: repoPath,
      name: path.basename(repoPath),
      branch,
      head,
      totalFiles: files.length,
      totalSizeBytes,
    },
    gitLog: collectGitLog(repoPath),
    todoFixme: countTodoFixme(repoPath, files),
    fileCountByExtension: collectExtensionCounts(files),
    largestFiles: collectLargestFiles(repoPath, files),
    partFiles: collectPartFiles(repoPath),
  };

  // Emit only after the document is fully assembled — never partial output.
  process.stdout.write(JSON.stringify(doc, null, 2) + "\n");
}

try {
  main();
} catch (e) {
  fail("unhandled error", {
    cause: String(e && e.message ? e.message : e),
    stack: e && e.stack ? String(e.stack) : undefined,
  });
}
