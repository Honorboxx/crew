# Crew

**Three specialist subagents and three skills for Claude Code — code review,
debugging, planning, and the discipline around them. Distilled from a working
production setup.**

These are prompt files, not magic: they plug into Claude Code's native
subagent (`.claude/agents/`) and skill (`.claude/skills/`) machinery and make
it do disciplined work — reviews that hunt outside the diff, debugging that
proves the cause before fixing, "done" that requires evidence. Each file is
written to a bar of: concrete method, failure-mode table, definition of done.
No filler.

## Install (60 seconds)

```bash
git clone https://github.com/Honorboxx/crew && cd crew
sh install.sh
```

That's it — the installer symlinks the pack into `~/.claude` (so `git pull`
updates it), tracks everything it installs in a manifest, and will not touch
files it doesn't own. `sh install.sh --dry-run` shows the plan first;
`--copy` detaches from the checkout; `--uninstall` removes exactly what it
installed; `--target some/project/.claude` installs per-project instead.
POSIX sh, zero dependencies.

## What's in the box

Everything is `crew-`prefixed so it never collides with your other packs.

### Agents (dispatched with a fresh context, report back)

**`crew-reviewer` — correctness pass.** Reads your diff three times: intent,
adversarial, and *outside the diff* — greps callers of everything you changed,
because most review-detectable bugs are in unchanged code whose assumptions
just broke. Findings ranked P0/P1/P2 with a concrete failing scenario each,
plus an explicit "checked and clean" list. Won't manufacture nits.

> *Recorded session (real, verbatim-condensed): crew-reviewer on a shipped
> commit of the store this pack funds — a markdown image/gallery feature the
> author had marked "(tested)". It found two P1s and a P2 in production code;
> all three were fixed the same hour.*
> ```
> crew-reviewer on 936ae3b "theme preview gallery" — verdict: fix before
> relying on it. Ran the suite (13/13 green) and the build (clean), then
> drove renderMarkdown with adversarial input.
>
> P1 scripts/lib/md.js:51 — image src interpolated raw into <img src="...">
>    while every other URL sink in the file is escaped. Demonstrated:
>    ![x](/a.png"onerror="alert(1) → <img src="/a.png"onerror="alert(1"...>
>    — an injected handler. The scheme allowlist doesn't help: the payload
>    starts with "/". Fix: escapeHtml the URL like link hrefs already do.
> P1 scripts/test/core.test.js:144 — the safety test is decoration: its
>    payload has a paren in the URL, so it fails the image-line regex and
>    never reaches the new filter; delete the filter and the test still
>    passes. Fix: paren-free unsafe src that actually hits the code path.
> P2 md.js:47-54 — an image run whose srcs are all rejected vanishes
>    silently: green build, missing content, zero signal.
>
> Checked and clean: both renderMarkdown callers wrap output in .prose so
> the new CSS applies (verified in dist/); 4 consecutive images group into
> one gallery, single → figure; block ordering doesn't mis-swallow
> paragraphs; alt text IS escaped; assets/ passthrough resolves; build
> idempotent; 13/13 existing tests meaningful except the one above.
> ```

**`crew-debugger` — root cause with receipts.** Reproduce → shrink → ranked
hypotheses → experiments that *eliminate* rather than confirm → fix → prove
(repro fails before, passes after, both outputs shown) → sweep for sibling
bugs. Keeps a hypothesis log so long sessions never re-test eliminated ideas.
Refuses to ship a fix without a causal chain.

> *Recorded session (real, verbatim-condensed): crew-debugger on the same
> production markdown bug crew-reviewer flagged — reproduced offline, root-
> caused, and proven with parse5 (the browser tokenizer) as ground truth.*
> ```
> crew-debugger — image src attribute injection (store markdown renderer)
>
> Repro (offline): ![x](/a.png"onerror=alert;//) →
>   <img src="/a.png"onerror=alert;//" ...>  ← parse5 confirms a LIVE onerror
>
> Hypotheses:
>   H1 image path interpolates src without escaping (alt IS escaped) — CONFIRMED
>   H2 the scheme allow-list leaks javascript:  — ELIMINATED (renders empty)
>   H3 the link path is the unsafe one            — ELIMINATED (inline() escapes first)
> Causal chain: allow-listed src containing a " closes src="..." early; the
>   tokenizer's missing-whitespace recovery reads the rest as new attributes.
> Fix: escapeHtml(src) at md.js:51. Before: 13 pass/1 new-test fail;
>   after: 14/0. Legit src (./assets/...) unchanged.
> Sibling sweep: build.js:74 interpolates payment_link into href with the same
>   unescaped pattern — lower severity (config-controlled), flagged + fixed.
> ```

**`crew-planner` — options, then a plan.** For tasks where the approach itself
is a decision. Recon in the codebase first, 2–3 genuinely different options
with the rejected one and why, then steps sized by risk — every step with an
observable done-check — and the section that matters most: explicit non-goals.

> *Example transcript (illustrative):*
> ```
> > plan the move from polling to webhooks with crew-planner
>
> ⏺ crew-planner: Option A keep polling + shrink interval (no new infra,
>   stays 30s-stale), Option B webhooks + polling fallback (chosen: real-time
>   where it matters, poller becomes the safety net), Option C webhooks only
>   (rejected: one missed delivery = silent data loss).
>   Plan: 5 steps, each with a done-check; riskiest first (signature
>   verification spike). Non-goals: no queue infra this round, no backfill.
> ```

### Skills (disciplines you invoke inline)

**`crew-verify` — evidence before claims.** The gate between finishing work
and describing work. Turns each claim ("fixed", "passing", "works") into the
cheapest observation that would prove it, made *this session* — and includes
the trick most setups miss: verify the verifier (green that can't go red is
not evidence). Anything unobserved ships labeled "changed, not verified".

> *Example (illustrative):*
> ```
> > /crew-verify then commit
> ⏺ Claims: (1) --target flag works (2) tests pass (3) README accurate.
>   (1) ran install.sh --target /tmp/p/.claude → 6 installed, links resolve ✓
>   (2) 47 passed — then reverted the fix for one run: 2 failed ✓ tests do
>       cover the change
>   (3) re-ran all 4 README commands as written ✓
>   Committing.
> ```

**`crew-scope` — size first, then plan that much.** S/M/L sizing by counting
plausible designs, a 5-line mini-plan for M tasks (every line objection-bait),
dispatch the planner for L. Kills both failure modes: coding an L blind, and
planning theater on an S. Plus the mid-task rule for "while I'm here" creep:
park it, don't chase it.

> *Example (illustrative):*
> ```
> > add a --json flag to the report command
> ⏺ crew-scope: M (one approach, three files).
>   Goal: report --json emits machine-readable output, exit codes unchanged.
>   Touches: cli.py, report.py, test_report.py
>   Risk: existing consumers parse stdout — keeping default output identical.
>   Non-goal: no schema versioning this round.
> ```

**`crew-git` — history as a communication act.** Atomic commits tested by
"can this revert alone", the staged-diff read-through (the medium switch that
catches debug prints), why-not-what messages, and a safe-repair table —
including the rule that matters when it matters: a leaked secret is *rotated
first*; history rewriting is only tidying.

> *Example (illustrative):*
> ```
> > commit this
> ⏺ crew-git: staged diff read-through first… found a stray console.log at
>   parser.js:88 and an unrelated rename mixed in. Unstaging the rename —
>   it goes in its own commit so the logic diff stays reviewable.
>   Commit 1: "Treat empty config as defaults, not error" (the why is in
>   the body). Commit 2: "Rename parse_cfg → parse_config (mechanical)".
> ```

## Free vs full

This repo is the free tier, and it's genuinely useful alone. The full pack is
the whole system — the same bar, ten agents and fourteen skills that
cross-reference each other, plus hooks and starter templates.

| | Crew (this repo) | [Crew Full — $19](https://honorboxx.github.io/honorbox/crew.html) |
|---|---|---|
| Agents | 3: reviewer, debugger, planner | 10: + simplifier (second review pass), tester, perf, security, refactorer, docs, release captain |
| Skills | 3: verify, scope, git | 14: + TDD, debug loop, self-review, PR authoring, changelog, release, docs pass, refactor, perf triage, security pass, handoff |
| Hook examples | — | 3, safe and commented (git guard, secret shield, format-on-edit) |
| CLAUDE.md starter templates | — | solo + team variants |
| Design doc | — | ROSTER.md: every agent/skill mapped to a job and a boundary |
| Installer | this one | same one, covering the full pack |
| Updates | `git pull` | private repo access; updates land there |
| License | MIT | per-developer commercial |

Buying replaces the six free files with superset versions (added
cross-references into the full system) — the installer handles it cleanly.

## Honest limits

- These improve *discipline*, not model capability. A model that can't find a
  bug won't find it because a prompt told it to be systematic — but it will
  stop claiming "fixed" without running the repro.
- Agents inherit your configured model and burn tokens like any subagent;
  the reviewer pass on a big diff is not free.
- Written for Claude Code's agent/skill format. Other tools may read the
  markdown fine, but the dispatch/invoke mechanics are Claude Code's.

## License

MIT — see [LICENSE](LICENSE).

---

*Repo description, for the fork bar: "Specialist subagents and skills for
Claude Code — rigorous code review, systematic debugging, planning, and
verification discipline. Free tier of Crew."*
*Topics: `claude-code` `claude` `subagents` `agents` `skills` `code-review`
`debugging` `developer-tools`*
