#!/usr/bin/env node
'use strict';
// SAMPLES.md is the whole argument for buying Crew: it says "everything quoted
// from the product below is verbatim, including its punctuation", and it tells
// the buyer to run the diff themselves and hold us to it. That promise is only
// as good as the last time somebody checked it, and checking it by hand does
// not survive contact with a second repo.
//
// It has already failed exactly that way. SAMPLES.md was regenerated from
// source at 18:21 one evening. Three hours later a commit in crew-full moved
// the release split between `crew-ship` and `crew-captain`, which rewrote two
// of the eighteen published descriptions and one line of the published diff.
// Nothing re-ran, because the commit that regenerated the page said it was
// "generated, not maintained by hand" while shipping nothing that could
// regenerate it. This is that missing thing.
//
// A separate defect it also catches: the page quoted a skill as saying
// "redesigns in denial", a string that appears nowhere in either repo. A
// fabricated quotation inside a section whose entire point is verbatim
// quotation is worse than a stale number, so quoted spans are resolved against
// the product rather than trusted.
//
//   node scripts/check-samples.js [--full ../crew-full]
//
// Exit 0 if every published claim still matches its source, 1 otherwise, with
// the mismatch printed as published-versus-actual.

const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');

const FREE = path.join(__dirname, '..');
const i = process.argv.indexOf('--full');
const FULL = path.resolve(i > -1 ? process.argv[i + 1] : path.join(FREE, '..', 'crew-full'));

const read = (p) => fs.readFileSync(p, 'utf8');
const flat = (s) => s.replace(/\s+/g, ' ').trim();
const failures = [];
const fail = (what, published, actual) => failures.push({ what, published, actual });

if (!fs.existsSync(FULL)) {
  console.error(`crew-full checkout not found at ${FULL}\nPass --full <path> if it lives elsewhere.`);
  process.exit(2);
}

const samples = read(path.join(FREE, 'SAMPLES.md'));

// ---- every prompt file in the paid pack, by its front-matter name -----------
function packFiles() {
  const out = [];
  for (const f of fs.readdirSync(path.join(FULL, 'agents'))) {
    if (f.endsWith('.md')) out.push(path.join(FULL, 'agents', f));
  }
  for (const d of fs.readdirSync(path.join(FULL, 'skills'))) {
    const p = path.join(FULL, 'skills', d, 'SKILL.md');
    if (fs.existsSync(p)) out.push(p);
  }
  return out;
}

function frontMatter(body) {
  const m = /^---\n([\s\S]*?)\n---\n/.exec(body);
  if (!m) return null;
  const name = /^name:\s*(.+)$/m.exec(m[1]);
  // description runs until the next top-level key, so it may wrap over lines
  const desc = /^description:\s*([\s\S]+?)(?=\n[a-z_]+:|$)/m.exec(m[1]);
  return name && desc ? { name: name[1].trim(), description: flat(desc[1]) } : null;
}

const bySource = new Map();
for (const p of packFiles()) {
  const fm = frontMatter(read(p));
  if (fm) bySource.set(fm.name, { ...fm, path: p });
}

// ---- 1. the eighteen published descriptions --------------------------------
// Section 4 is the page's own honesty control ("judge density rather than trust
// a sample"), so a superseded description there is not cosmetic: it shows the
// buyer an architecture the pack no longer has.
let published = 0;
for (const m of samples.matchAll(/^- \*\*`([a-z-]+)`\*\*: (.+)$/gm)) {
  published++;
  const src = bySource.get(m[1]);
  if (!src) { fail(`description for ${m[1]}`, 'published', 'no such file in the pack'); continue; }
  if (flat(m[2]) !== src.description) fail(`description for ${m[1]}`, flat(m[2]), src.description);
}
if (published !== 18) {
  fail('count of published descriptions', String(published), '18, as the page and the product page both claim');
}

// ---- 2. quoted spans exist in the product ----------------------------------
// The page presents these as the product's own words. Resolving them against
// every file is deliberately loose: it does not care WHICH file a quote came
// from, only that somebody could have written it. That is enough to catch an
// invented one, and it never argues about attribution.
const corpus = packFiles().map((p) => flat(read(p)));
for (const m of samples.matchAll(/\*"([^"]{15,})"\*/g)) {
  const q = flat(m[1]).replace(/\.$/, '');
  if (!corpus.some((c) => c.includes(q))) {
    fail('quoted as the product\'s own words', q, 'this string appears in no file in either repo');
  }
}

// ---- 3. the published diffs are the real diffs ------------------------------
// Section 1 invites the buyer to run these and hold us to it, which makes a
// drifted hunk the single most checkable lie on the page.
for (const m of samples.matchAll(/^\$ diff (\S+) (\S+)\n([\s\S]*?)(?=\n\$ diff |\n```)/gm)) {
  const [, left, right, block] = m;
  const lp = path.join(FREE, left.replace(/^crew\//, ''));
  const rp = path.join(FULL, right.replace(/^crew-full\//, ''));
  if (!fs.existsSync(lp) || !fs.existsSync(rp)) {
    fail(`diff ${left} ${right}`, 'published', 'one of these paths does not exist');
    continue;
  }
  let actual = '';
  try {
    execFileSync('diff', [lp, rp], { encoding: 'utf8' });
  } catch (e) {
    actual = e.stdout || ''; // diff exits 1 when files differ, which is expected
  }
  if (flat(actual) !== flat(block)) fail(`diff ${left} ${right}`, flat(block), flat(actual));
}

// ---- 4. how many hooks we say we ship --------------------------------------
// "Three hooks" outlived the third hook by three more, in three places at once,
// while the pack's own hooks/README.md described five guards plus a convenience.
// Not every shell file in hooks/ is a hook: shell-tree.sh is sourced by the
// Bash guards and never registered against an event. The pack's own
// hooks/README.md already says which is which, in the Event column, so read
// that rather than keeping a second list here that can drift from it. The
// directory scan stays: a new hook file that nobody documented is exactly the
// drift this check exists to catch, and it still counts.
const notHooks = new Set(
  [...read(path.join(FULL, 'hooks', 'README.md'))
    .matchAll(/^\|\s*`([\w-]+\.sh)`\s*\|\s*\*?\(?not a hook\)?\*?\s*\|/gim)]
    .map((m) => m[1]),
);
const hooks = fs.readdirSync(path.join(FULL, 'hooks'))
  .filter((f) => f.endsWith('.sh') && !f.startsWith('test-') && f !== 'run-tests.sh')
  .filter((f) => !notHooks.has(f));
const WORDS = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'];
for (const f of ['SAMPLES.md', 'README.md']) {
  const body = read(path.join(FREE, f));
  for (const m of flat(body).matchAll(/\b(\w+) (?:safety |commented |auditable )*(?:shell )?hooks?\b/gi)) {
    const said = m[1].toLowerCase();
    const n = WORDS.indexOf(said) > -1 ? WORDS.indexOf(said) : Number(said);
    if (!Number.isFinite(n) || n === 0) continue; // "the hooks", "these hooks"
    if (n !== hooks.length) {
      fail(`${f}: hook count`, `${said} hooks`, `${hooks.length}: ${hooks.join(', ')}`);
    }
  }
}

// ---- report ----------------------------------------------------------------
if (!failures.length) {
  console.log(`SAMPLES.md matches the product: ${published} descriptions, ${hooks.length} hooks, every diff and every quote.`);
  process.exit(0);
}
console.error(`SAMPLES.md disagrees with the product in ${failures.length} place(s).\n`);
for (const f of failures) {
  console.error(`  ${f.what}`);
  console.error(`    published: ${String(f.published).slice(0, 160)}`);
  console.error(`    actual:    ${String(f.actual).slice(0, 160)}\n`);
}
console.error('Fix SAMPLES.md, not this script. The product is the source of truth.');
process.exit(1);
