# Crew, in the open

Crew is a pack of prompt files. The only question a buyer actually has is
"are these any good," and that is exactly the thing a private repo hides
until after the money moves. A feature list does not answer it. Twenty-four
markdown files behind a paywall answer it even less.

So this page is the answer, in the form of things you can check rather than
things we assert:

1. [The exact diff](#1-what-buying-changes-about-the-files-you-already-have)
   between the six free files you already have and their paid counterparts.
2. [A complete paid agent](#2-a-complete-paid-agent-crew-simplifier), full text.
3. [A complete paid skill](#3-a-complete-paid-skill-crew-perf-triage), full text.
4. [Every paid-only file's description](#4-all-18-paid-only-files-in-their-own-words),
   all eighteen, so you can judge density rather than trust a sample.
5. [A real recorded run](#5-a-real-run-free-and-paid-on-the-same-public-commit):
   the free reviewer and a paid agent on the same public commit of a real
   repo, with the bug they found still linked.
6. [The hooks and the output of their test suite](#6-the-hooks-and-their-test).
7. [The three files we think are weakest](#7-where-the-pack-is-weakest), named
   by us, before you find them yourself.

A note on the sample choice, because it matters. We did **not** pick the two
published files at random and we are not going to claim they are
representative. We picked the two we think are the strongest in the pack.
That is cherry-picking, and telling you it is not would be the first thing on
this page you could catch us in. Section 4 is the control: if Crew were two
good files and sixteen pieces of filler, eighteen consecutive descriptions
would make that obvious in about ninety seconds.

Everything quoted from the product below is verbatim, including its
punctuation.

---

## 1. What buying changes about the files you already have

The free repo ships three agents and three skills. The paid pack ships its own
copies of those same six. A reasonable worry: are the free ones a cut-down
teaser, with the good paragraphs held back?

Here is the complete difference, produced by `diff`. Run it yourself after you
buy, against this repo, and hold us to it:

```
$ diff crew/agents/crew-reviewer.md crew-full/agents/crew-reviewer.md
10c10,12
< defects. Your report is the deliverable; you never edit files.
---
> defects. Your report is the deliverable; you never edit files. Reduction of the
> diff is a separate dispatch (`crew-simplifier`) that runs after you pass it,
> precisely so that neither pass dilutes the other.
36c38,39
< that passes before and after the change is decoration.
---
> that passes before and after the change is decoration. (Deep suite audits are
> `crew-tester`'s mutation-standard job — flag the need rather than doing it.)

$ diff crew/agents/crew-planner.md crew-full/agents/crew-planner.md
10a11,14
> You are typically dispatched when `crew-scope` sizes a task L — approach
> itself in question, fuzzy done condition, or schema/API/money in the blast
> radius. Your per-step done-checks become the implementer's `crew-verify`
> targets, so make each one observable.

$ diff crew/agents/crew-debugger.md crew-full/agents/crew-debugger.md
10c10,12
< cheap. You do not propose a fix until you can state the causal chain from
---
> cheap — usually as the escalation target of the inline `crew-debug` skill.
> If the dispatcher hands you a repro and a ruled-out list, start from it, not
> from zero. You do not propose a fix until you can state the causal chain from

$ diff crew/skills/crew-git/SKILL.md crew-full/skills/crew-git/SKILL.md
23a24
>   (The full pre-handoff version of this read is `crew-self-review`.)

$ diff crew/skills/crew-verify/SKILL.md crew-full/skills/crew-verify/SKILL.md
62a63,67
>
> This gate feeds the rest of the system: the evidence you gather here is what
> gets pasted into PR descriptions (`crew-pr`), what `crew-ship`'s checklist
> items mean by "green", and what a handoff note (`crew-handoff`) may list
> under "done". None of those accept the claim without the observation.

$ diff crew/skills/crew-scope/SKILL.md crew-full/skills/crew-scope/SKILL.md
47c47,49
< test elsewhere): park it in a follow-ups list and finish the scoped task.
---
> test elsewhere): park it in a follow-ups list and finish the scoped task. The
> parked list is also the feed for dispatched passes later — structural items
> become `crew-refactorer` mandates, suite gaps become `crew-tester` runs.
```

That is the whole delta: six insertions, every one of them a pointer to a
component the free tier does not include. Nothing is withheld from the free
files. What you are buying is not better versions of these six, it is the
other eighteen plus the wiring between them, and the diff is what that wiring
physically looks like.

It also means the free tier is an honest sample of the writing. Judge the bar
on `crew-reviewer` and you have judged it on files you have not read.

---

## 2. A complete paid agent: crew-simplifier

Not an excerpt. This is `agents/crew-simplifier.md` as shipped, front matter
included. A recorded run of this exact file is in
[section 5](#5-a-real-run-free-and-paid-on-the-same-public-commit), so you can
compare what the file demands against what it actually produced.

````markdown
---
name: crew-simplifier
description: Dispatch after a correctness review (crew-reviewer) passes — the second review pass that shrinks the diff. Finds deletions, existing helpers being reimplemented, needless abstraction, and surface that can narrow. Returns proposed reductions with a net-line delta and a behavior-preservation argument for each; changes nothing itself.
tools: Read, Grep, Glob, Bash
---

# crew-simplifier — the shrinking pass

You run *after* correctness review, never instead of it, and never merged
into it: a brain hunting bugs pattern-matches differently from one hunting
redundancy, which is exactly why this is a separate dispatch. Your question
is not "is it right?" but "how much of it needs to exist?"

## Where reduction hides

Work the diff against the *codebase's existing vocabulary* — the best
simplification is usually not rewriting the new code, it's discovering it was
already written:

- **Reimplemented helpers.** For every new utility, validation, formatting,
  or retry block in the diff: grep the codebase (and skim the stdlib of the
  language) for the thing it duplicates. New code earns its place only after
  the search comes up empty.
- **Speculative generality.** Parameters with exactly one call-site value,
  interfaces with one implementation, config nobody sets, "for future use"
  branches. The future can add these back the day it actually arrives, at
  the same cost — carrying them until then is pure interest.
- **Dead weight the diff creates.** Code the change orphaned: the old code
  path kept "just in case", exports nothing imports anymore, tests for
  deleted behavior. `grep` for callers before calling anything dead.
- **Surface that can narrow.** Public that can be private, exported that can
  be local, three options that can be one. Narrowing later is a breaking
  change; narrowing now is free.
- **Flow that can flatten.** Nesting an early return removes; a condition
  that reads backwards; two branches that are the same branch wearing
  different clothes.

## What is NOT simplification

| Tempting | Why you leave it alone |
|---|---|
| DRY-ing two blocks that merely look alike today | Coincidental duplication; merging couples two things that will diverge, and the wrong abstraction costs more than the duplication |
| Compressing to a clever one-liner | Fewer characters, higher reading cost — you optimize reads, not bytes |
| Deleting "redundant" error handling | That handler may be the only thing standing between a partial failure and silent corruption — prove it dead before touching it |
| Style-only churn (rename, reorder, reformat) | Not your pass; it bloats the diff you were sent to shrink |
| Redesigning the approach | If the whole shape is wrong, say so in one paragraph and stop — that's a planning conversation, not a simplification |

## Report format

Each proposal: location, the reduction, **net line delta**, and one sentence
of *behavior-preservation argument* ("same three call sites, output
byte-identical, error path unchanged — verified by running X"). Where you can
cheaply run the tests to back the argument, run them and say so. Rank by
delta-per-risk: big safe deletions first, subtle narrowings last. If the diff
is already tight, report exactly that — "no reductions worth their risk" is a
pass, and a valuable one.

## Done when

Every new name in the diff has been challenged for an existing equivalent;
every proposal carries its preservation argument; nothing proposed is taste
dressed as reduction. The author should be able to apply your report
top-to-bottom in one sitting.
````

---

## 3. A complete paid skill: crew-perf-triage

Again complete, as shipped. This one is the shape most of the skills take: a
short discipline with an ordered checklist and an explicit stop condition.

````markdown
---
name: crew-perf-triage
description: Use the moment something seems slow — the five-minute triage that turns "feels slow" into a number, checks the complexity-class suspects that cause most real slowness, and records the baseline. Escalates to the crew-perf agent with numbers in hand, never with feelings.
---

# crew-perf-triage — five minutes before any optimization

Most production slowness is *categorical* — the wrong complexity class, not
an accumulation of small inefficiencies. That's why a five-minute triage
catches the majority of real cases, and why optimizing anything before this
triage is a random walk with a profiler-shaped hole in it.

## Minute 1 — turn the feeling into a number

Measure the slow thing with the cheapest honest tool: `time` on the command,
a timer around the operation, the browser network tab, `EXPLAIN ANALYZE` on
the query. Write the number down — **this baseline is the one thing you
cannot reconstruct later**, and without it no future fix can prove itself.
Then ask: slow compared to *what*? A 2-second cold start might be fine; a
2-second autocomplete is broken. No expectation gap, no problem — stop here
(this outcome is common and is a success).

## Minutes 2–4 — check the usual suspects, in order

The categorical causes, ordered by hit rate. Grep and log-count; no profiler
needed yet:

1. **N+1** — a query/API call inside a loop over results. Tell: count of
   queries scales with rows. One log line or query counter answers it.
2. **Accidental quadratic** — `list.contains` in a loop, string concat in a
   loop, nested scans of the same collection. Tell: fine at 100 items, dead
   at 10,000.
3. **Sync I/O in the hot path** — network/disk serialized inside a loop
   that could batch or parallelize. Tell: wall time >> CPU time.
4. **Missing index** — `EXPLAIN` says seq scan on a big table under a
   filter/join. One command to check.
5. **Chatty round-trips** — dozens of small calls where one bulk call
   exists. Tell: latency × call-count ≈ total time.
6. **Loading the world** — fetching/parsing far more than needed (the
   `SELECT *` of files, APIs, and configs).

Found one? Fix that one thing, re-measure against your baseline, done —
don't continue into micro-territory on momentum; past the categorical fix,
returns collapse and risk doesn't.

## Minute 5 — escalate honestly

Suspects clean but the gap is real → hand `crew-perf` the number, the
expectation, the workload, and which suspects you already cleared. That
handoff is the difference between an investigation that starts at
attribution and one that re-does your five minutes at agent prices.

## Failure modes

| Move | Why it's a trap |
|---|---|
| Optimizing from the feeling | The bottleneck is reliably not where intuition points; that's the whole reason profilers exist |
| Reaching for a cache in minute 2 | A cache atop an N+1 hides the class bug under an invalidation bug |
| Measuring once | One run measures noise; even the cheap tools get 3 runs |
| Fixing two suspects at once | The re-measure can't attribute the win; you've learned nothing reusable |
| Skipping the baseline "to save time" | The fix now ships as "feels faster" — unprovable, unrevertable-with-confidence |
````

---

## 4. All 18 paid-only files, in their own words

Two full files prove a ceiling, not a floor. This is the floor check.

Below is the `description` field of every one of the eighteen files you do not
get for free, verbatim and in full, with nothing skipped. The description is
not marketing copy: it is the string Claude Code reads to decide whether to
dispatch that agent, so it has to state the file's actual job in one breath.
Eighteen of them in a row is the cheapest honest way to see whether every file
has a thesis or whether some are making up the numbers.

### Agents (7)

- **`crew-simplifier`** — Dispatch after a correctness review (crew-reviewer) passes — the second review pass that shrinks the diff. Finds deletions, existing helpers being reimplemented, needless abstraction, and surface that can narrow. Returns proposed reductions with a net-line delta and a behavior-preservation argument for each; changes nothing itself.
- **`crew-tester`** — Dispatch to write tests for new or existing code, or to audit a test suite's actual strength. Enumerates boundary cases before writing anything, applies the mutation standard (every test must have a plausible bug it would catch), and reports suite verdicts as would-fail evidence, not coverage percentages.
- **`crew-perf`** — Dispatch for a full performance investigation once something is measurably slow — after the 5-minute crew-perf-triage skill has numbers and the obvious complexity-class suspects came up clean. Defines the metric, baselines, profiles to attribute, fixes the top item, and re-measures with variance. Returns numbers, never adjectives.
- **`crew-security`** — Dispatch to security-review a feature, endpoint, or diff with real attack surface — auth flows, input parsing, file handling, anything that builds queries, URLs, or shell commands, anything touching secrets. Traces untrusted input to sinks, checks the classes app teams actually get burned by, and returns findings with a concrete attack sketch each plus an explicit coverage list. Basics done rigorously — not a pentest.
- **`crew-refactorer`** — Dispatch for structural work bigger than the current task — untangling a module, extracting a layer, killing a god object — where behavior must provably not change. Works toward a shape goal named in advance, in mechanical always-green steps, and refuses to mix in fixes or features. For small inline cleanups the crew-refactor skill applies instead.
- **`crew-docs`** — Dispatch to write or overhaul a document — README, getting-started, how-to, architecture note, runbook. Picks the doc type deliberately, writes for the reader's task rather than the code's structure, and runs every command before it ships. For keeping existing docs truthful after a code change, the crew-docs-pass skill applies instead.
- **`crew-captain`** — Dispatch to take a branch from "code done" to "released" — preflight checks, version decision derived from the public-surface diff, user-facing changelog assembled, tag, publish, and the post-publish smoke test of the actual artifact. Owns the mechanics of shipping, not the decision to ship.

### Skills (11)

- **`crew-tdd`** — Use when implementing a feature or bugfix where the behavior can be stated as a test — enforces the red/green/refactor loop with the two checks that make it real: the test observed failing for the right reason, and one behavior per cycle. Includes the honest list of where TDD doesn't pay.
- **`crew-debug`** — Use the moment a bug, failing test, or unexpected behavior appears mid-task — the inline debugging loop that prevents guess-and-check spirals. Defines the exact escalation point for dispatching the crew-debugger agent.
- **`crew-self-review`** — Use after finishing a change and before committing, requesting review, or dispatching crew-reviewer — the hostile read of your own full diff that catches what authors leak: leftovers, accidental files, unpulled threads. Cheap, and it keeps the real reviewers working on real problems.
- **`crew-pr`** — Use when opening a pull request — writes the description as a review map (why, review order, pasted evidence, risk and rollback) and enforces the size and scope rules that determine whether the PR gets reviewed or skimmed.
- **`crew-changelog`** — Use when merging any user-visible change, and when cutting a release section — keeps a changelog that is written at merge time, in the user's voice, with migration notes where they're owed. The thirty-second habit that makes crew-ship's job mechanical.
- **`crew-ship`** — Use when cutting a release inline — the preflight and publish checklist: version consistency, tag-built artifact, the post-publish smoke test from an environment that never saw your checkout, and a rollback named before it's needed. For large or unfamiliar releases, dispatch crew-captain instead.
- **`crew-docs-pass`** — Use after any code change that alters behavior, names, flags, config, or setup — hunts down every documented statement the change just made false, and re-runs every touched command. Docs are an artifact of the change, not a separate chore. For writing net-new documents, dispatch crew-docs.
- **`crew-refactor`** — Use when improving code structure inline — during a feature, after a green TDD cycle, or boy-scouting near your change. Enforces the pin-first, mechanical-steps, separate-commits discipline at small scale, with a hard boundary on scope. Structural work beyond the current task goes to the crew-refactorer agent.
- **`crew-perf-triage`** — Use the moment something seems slow — the five-minute triage that turns "feels slow" into a number, checks the complexity-class suspects that cause most real slowness, and records the baseline. Escalates to the crew-perf agent with numbers in hand, never with feelings.
- **`crew-security-pass`** — Use on every diff, at review or self-review time — the sixty-second check that triggers on security surfaces touched, runs the matching mini-checklist, and either clears the diff explicitly or escalates to the crew-security agent. Security review that fires on surfaces, not on schedules.
- **`crew-handoff`** — Use when ending a session mid-task, approaching context limits, or passing work to another person or agent — writes the handoff note that lets the next context resume in minutes instead of re-deriving an afternoon. The most valuable section is the one only you can write: what was already ruled out.

Plus, not counted above: three commented shell hooks with a test suite
(section 6), CLAUDE.md starter templates for solo and team repos, `ROSTER.md`
(the design document that assigns every file a job and an explicit *not* its
job), and `UPGRADING.md`.

---

## 5. A real run: free and paid on the same public commit

Recorded runs, not illustrations. Both agents were dispatched against the same
target: commit
[`68c6fee`](https://github.com/Honorboxx/honorbox/commit/68c6fee) of
[Honorboxx/honorbox](https://github.com/Honorboxx/honorbox), the open-source
store engine that sells this pack. The commit is public, so every claim below
can be checked against the actual diff.

The point of running two agents on one diff is the thing hardest to
demonstrate about a roster: that the files stay in their lanes. `crew-reviewer`
is free and you already have it. `crew-simplifier` is paid and printed in full
in [section 2](#2-a-complete-paid-agent-crew-simplifier). If the paid one
mostly repeats the free one, you should not pay for it, and this section is
where you would catch that.

Method, so you can reproduce it: each agent file was supplied verbatim as the
subagent's operating instruction, with the dispatch "review commit 68c6fee."
Neither was told what to look for. Both were denied write access, which is
what `ROSTER.md` specifies for reporting agents. Output is unedited except for
trimming to fit this page, marked where it happens.

### 5a. `crew-reviewer` (free tier)

It opened by testing the commit message's central claim against the code
rather than accepting it:

```
The central claim holds. I exercised the guard against the real store.config.json:

live config          : 0 problems  isUpstream=true
followed setup.md    : 9 problems  isUpstream=false
untouched fork       : 0 problems  isUpstream=true

The "nine leftovers" in the commit message is exact, and the upstream store is
not false-positived. The old guard returned [] for the `followed setup.md` case
— the regression is real and is now closed.
```

Then it found a real bug, on a money path, that had nothing to do with the
commit's stated subject:

```
P1 — `--dry-run=true` is accepted as a valid flag, then silently ignored, and
creates live Stripe objects

scripts/init.js:33 (`has`), :35 (KNOWN_FLAGS), :118-121, :147

This commit teaches `--flag=value` and adds a validator that normalizes
`--dry-run=true` → `dry-run` and declares it known. But `has()` is still
`process.argv.includes('--dry-run')`, an exact-token match, so the flag
evaluates false and the dry-run gate at :147 is never reached.

Verified — this reached the network:

  $ STRIPE_SECRET_KEY=rk_test_x node scripts/init.js --name=T --price=2900 \
      --repo=o/r --config=store.config.json --dry-run=true --yes
  This will create LIVE Stripe objects on your account:
  init: /v1/products: Invalid API Key provided: rk_test_x

It only stopped because the key was fake. Concrete failure: a CI or Makefile
step runs `init.js --yes --dry-run=true` against a live `rk_`; a Product, Price,
and Payment Link are created on the seller's account by a command that asked
for a preview.

To be fair on attribution: pre-commit, `--dry-run=true` also created live
objects. The commit does not introduce the bug, but it advertises the `=`
spelling and then blesses this specific token as valid, which turns a typo into
something that looks supported.
```

This one is real. We reproduced it by hand before publishing this page:

```
--- CONTROL: --dry-run (bare) ---
  link      Payment Link with required "GitHub username" field
  delivery  invite to o/r

dry run — nothing created.

--- BUG: --dry-run=true ---
  link      Payment Link with required "GitHub username" field
  delivery  invite to o/r

init: /v1/products: Invalid API Key provided: rk_test_fake
```

The bare flag stops. The `=true` spelling walks straight into the Stripe API
and is stopped only by the fake key. It is a footgun aimed at the seller's own
account rather than an attack anyone else can run, but it is exactly the class
of thing that is invisible until it costs somebody a stray live Payment Link.
It is unfixed as of this writing. We are leaving it in the transcript rather
than cutting the paragraph that makes our own engine look bad, because a
transcript edited for flattery is not evidence of anything.

Three further P2s followed (an exact-string URL match that will break the
upstream store the day it moves to a custom domain, a `--help` flag listed as
known but unhandled, an empty `--id=` blaming the wrong flag), then the section
the file requires and most reviews omit:

```
Checked and clean:

- Own-store false positive — live store.config.json → isUpstream=true, 0 problems.
- Callers of the changed surface — templateProblems has exactly one production
  caller (build.js:542) ... Newly exported isUpstreamStore is consumed only by
  core.test.js. Grepped repo-wide including workflows and docs.
- Newly-mandatory `repo` — every other reader (build.js:170 sameAs, :530
  rewriteDocLinks, :577 footer, :624 CTA) already guards on truthiness, so no
  undefined propagates.
- Partial failure / ordering in init.js — the new non-TTY die fires after the
  config read and before the first Stripe call, with created[] empty; no
  half-created state, no leaked readline handle.
- Doc line counts — fulfill.js 229, fulfill-core.js 223 at that commit. Both
  claims correct.

Verdict: merge. No P0. Fix the P1 in a follow-up before anyone is pointed at
the `--flag=value` spelling on a money path.
```

[Trimmed: two further "checked and clean" entries and a low-confidence question
about using `GITHUB_REPOSITORY` to close a remaining hole.]

### 5b. `crew-simplifier` (paid tier)

Same diff, same repo, no knowledge of the review above. It is not looking for
bugs. Note that it did the verification work its own file demands, including
mutation-testing an assertion to prove it was redundant rather than asserting
it:

```
Verification setup. The repo was not modified. I copied the working tree to a
scratch directory and applied all four proposals there. Baseline
`node --test scripts/test/*.test.js` = 130 pass / 0 fail; with proposals 1–4
applied = 129 pass / 0 fail (129 because proposal 4 folds one test into
another), and `node scripts/build.js` still exits 0.

The diff is mostly tight. Four reductions are worth their risk, totalling
−13 lines and two names removed from advertised surface.
```

```
3. Un-export `isUpstreamStore` — build.js:774, core.test.js:16, 923, 934
Net delta: −3 lines, −1 exported name.

grep -rn isUpstreamStore --include="*.js" . gives exactly four sites ... So the
export exists purely for two assertions that are already implied by their
neighbours.

I proved the implication rather than asserting it. With both assertions and the
export removed, I forced isUpstreamStore to return a constant and re-ran
core.test.js:

  === isUpstreamStore forced to true ===   ✖ 2 failing, 87 pass
  === isUpstreamStore forced to false ===  ✖ 2 failing, 87 pass

Both mutants are still caught. No coverage is lost, and narrowing now is free
where narrowing later is a breaking change to a module the tests treat as API.
```

It also declined proposals, with reasons, which is the half of a shrinking pass
that keeps it from becoming vandalism:

```
Considered and rejected — reported so you can see the search was done

- Merging trimSlash into checkoutKey (build.js:323). They both strip trailing
  slashes, so they look mergeable. They are not: checkoutKey also lowercases and
  drops everything past ?/#. Applied to config.url that would make
  HTTPS://HONORBOXX.GITHUB.IO/HONORBOX?x=1 register as the upstream store —
  loosening a money guard in the one direction you never want. Coincidental
  duplication; leave them apart.

- node:util.parseArgs would subsume arg, has, and unknownFlags (~26 lines → ~12).
  It is stdlib, so the zero-dependency promise holds ... I am not recommending
  it. It is a rewrite of a parser this very commit just fixed, it discards the
  comments that record why, and strict: true throws where the file's idiom is
  die(). I did not build or test it. Noted because the brief asks me to check
  the stdlib, not because it should ship in this pass.

- The long explanatory comments in both files. They are the most conspicuous new
  lines in the diff and they are not bloat: each one records a specific failure
  mode that a future reader would otherwise re-introduce. Deleting prose to
  shrink a line count is the opposite of optimizing for reads.
```

And it priced its own weakest proposal honestly instead of padding the count:

```
Honest cost, rank it accordingly: this is the one proposal that spends
something. Test names in this suite are documentation — each is a sentence about
a real bug — and folding retires the sentence "stops demanding a Stripe key for
--dry-run" into an assertion message. If you value the named regression more
than seven lines, decline this one; the other three are free.
```

[Trimmed: proposals 1, 2 and 4 in full, and four further rejected candidates.]

### What the two runs actually showed

Findings from the free reviewer: one P1 and three P2 defects, plus a
would-it-fail audit of all five new tests.

Findings from the paid simplifier: four reductions totalling −13 lines and two
names removed from module surface, each with a behavior-preservation argument,
plus seven candidates considered and rejected with reasons.

They overlapped on exactly one observation out of sixteen, and disposed of it
differently: both noticed that `--help` is listed as a known flag but does
nothing. The reviewer filed it as a defect and said implement it. The
simplifier proposed deleting it from the list and explicitly refused to
implement it, on the grounds that adding a feature is not a shrinking pass.
Same fact, two correct and opposite dispositions, neither agent wandering into
the other's job.

That is the entire argument for a designed roster over a pile of prompts, and
it is the reason the boundary lines exist in the diff in
[section 1](#1-what-buying-changes-about-the-files-you-already-have).

---

## 6. The hooks and their test

The paid pack ships three hooks as commented, auditable POSIX shell: a git
guard, a secret shield, and post-edit formatting. Shell that intercepts your
git commands should not be taken on trust, so the git guard ships with a test
you can read and run.

`sh hooks/test-git-guard.sh`, run while writing this page, unedited:

```
blocked — explicit force flags:
  ok    exit=2  git push --force origin main
  ok    exit=2  git push -f origin main
  ok    exit=2  git push --force origin feature
blocked — force by refspec (+), the form that used to slip through:
  ok    exit=2  git push origin +main:main
  ok    exit=2  git push origin +refs/heads/main:refs/heads/main
  ok    exit=2  git push origin +main
  ok    exit=2  git push origin +feature:feature
blocked — force-with-lease onto a protected branch:
  ok    exit=2  git push --force-with-lease origin main
  ok    exit=2  git push --force-with-lease origin release-1
  ok    exit=2  git push --force-with-lease origin release/2026-07
  ok    exit=2  git push --force-with-lease origin release_rc2
  ok    exit=2  git push origin --delete release-1
blocked — deleting a protected branch:
  ok    exit=2  git push origin --delete main
  ok    exit=2  git push origin :main
  ok    exit=2  git branch -D main
allowed — ordinary work:
  ok    exit=0  git push origin feature-x
  ok    exit=0  git push
  ok    exit=0  git status
  ok    exit=0  git commit -m "wip"
  ok    exit=0  git branch -D scratch
  ok    exit=0  git push --force-with-lease origin my-feature

git-guard: all cases behaved as specified.
```

Twenty-one cases, including the six that must be *allowed*, which is the half
of a guard that determines whether you keep it switched on.

---

## 7. Where the pack is weakest

You will find these after buying, so here they are first. This is our own
assessment, and it is the section we would most like to delete.

**`crew-refactor` and `crew-refactorer` overlap more than they should.** The
split is real in principle (an inline discipline versus a dispatched agent for
structural work), and each has content the other does not: the skill owns the
`git bisect` argument and the boy-scout boundary, the agent owns
characterization tests and golden-masters. But roughly half the skill restates
the agent in different words. The rule of three, the extract/inline/move/rename
list, the preference for tool-assisted renames, and the unpinned-code argument
all appear twice, down to the thesis line: the agent says *"Most refactors that
go wrong were secretly redesigns that never admitted it"* and the skill says
*"Most refactors that go wrong were redesigns in denial."* If you buy the pack
and feel you paid for one of these twice, that is a fair reading. `ROSTER.md`
says overlap is a bug and asks you to file an issue; this one we found
ourselves and have not fixed yet.

**`crew-changelog` and `crew-docs` lean on public standards more than the rest
of the pack does.** `crew-changelog` is built on Keep a Changelog's vocabulary
and says so; if you have read that page, the file adds about one idea
(reconstructed release notes should be labelled as reconstructed).
`crew-docs`'s centerpiece is the four-type documentation taxonomy of
tutorial / how-to / reference / explanation, which is Divio's widely published
system (Daniele Procida's Diátaxis). The file shipped without crediting it.
That was our mistake, it was ours to catch and we caught it late, and the
credit is now in the file. Both files are well written. Neither is as original
as the pack's better half.

**So the honest shape of the pack is not a flat bar.** The strongest files
(`crew-security-pass`, `crew-tester`, `crew-perf-triage`, `crew-simplifier`)
are reference artifacts we keep open during real work. The weakest three are
competent summaries. Fifteen of the eighteen we would defend line by line;
three we would rewrite before we would defend. If your read of section 4 is that
eighteen descriptions still look worth nineteen dollars with those caveats
priced in, that is the decision we would want you to make.

---

## Honest limits

Unchanged from the free tier's README, and they apply to everything above:

- These improve **discipline**, not model capability. A model that cannot find
  a bug will not find it because a prompt told it to be systematic. It will
  stop claiming "fixed" without running the repro.
- Agents inherit your configured model and burn tokens like any subagent. The
  reviewer pass in section 5 was not free to run, and neither was the
  simplifier pass.
- Written for Claude Code's agent and skill format. Other tools may read the
  markdown fine, but the dispatch and invoke mechanics are Claude Code's.
- Two recorded runs on one commit are two data points. They are real, and they
  are not a benchmark.

---

[Crew Full is $19](https://honorboxx.github.io/honorbox/crew.html) with a
30-day no-questions refund. The free tier in this repo stays free and MIT
whatever you decide.
