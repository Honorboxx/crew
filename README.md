# Crew

**Three specialist subagents and three skills for Claude Code: code review,
debugging, planning, and the discipline around them.**

These are prompt files, not magic. They plug into Claude Code's native
subagent (`.claude/agents/`) and skill (`.claude/skills/`) machinery and make
it do disciplined work: reviews that hunt outside the diff, debugging that
proves the cause before fixing, "done" that requires evidence. Each file is
written to the same bar: concrete method, failure-mode table, definition of
done. The recorded sessions below are what that produced on real code.

## Install

```bash
git clone https://github.com/Honorboxx/crew && cd crew
sh install.sh
```

The installer symlinks the pack into `~/.claude` (so `git pull`
updates it), tracks everything it installs in a manifest, and will not touch
files it doesn't own. `sh install.sh --dry-run` shows the plan first;
`--copy` detaches from the checkout; `--uninstall` removes exactly what it
installed; `--target some/project/.claude` installs per-project instead.
POSIX sh, zero dependencies.

## What's in the box

Everything is `crew-`prefixed so it never collides with your other packs.

### Agents (dispatched with a fresh context, report back)

**`crew-reviewer`: correctness pass.** Reads your diff three times: intent,
adversarial, and *outside the diff*. Greps callers of everything you changed,
because most review-detectable bugs are in unchanged code whose assumptions
just broke. Findings ranked P0/P1/P2 with a concrete failing scenario each,
plus an explicit "checked and clean" list. Won't manufacture nits.

> *Recorded session (real, verbatim-condensed): crew-reviewer on a shipped
> commit of the store this pack funds, a markdown image/gallery feature the
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

**`crew-debugger`: root cause with receipts.** Reproduce → shrink → ranked
hypotheses → experiments that *eliminate* rather than confirm → fix → prove
(repro fails before, passes after, both outputs shown) → sweep for sibling
bugs. Keeps a hypothesis log so long sessions never re-test eliminated ideas.
Refuses to ship a fix without a causal chain.

> *Recorded session (real, verbatim-condensed): crew-debugger on a real
> production incident, a fulfillment failure that got an order permanently
> stuck. No live APIs: it ran the real engine as a child process with only the
> network faked, replaying the verbatim production error.*
> ```
> Incident: fulfillment logged FAILED ... invite <owner> -> 422
>   "Repository owner cannot be a collaborator" when the store owner
>   test-bought their own product. The catch path marked the session
>   processed → TERMINAL: ledger needs_attention, no retry.
>
> Repro (decision path, not HTTP): real fulfill.js as a child process,
>   global.fetch stubbed to documented PUT-collaborator semantics + the
>   verbatim 422 body. Symptom reproduced byte-identically.
> Hypotheses:
>   H1 wrong username/repo plumbing — ELIMINATED (prod state shows correct
>      field + grant flowed through; engine did the right thing)
>   H2 no owner-self-purchase guard   — CONFIRMED (invites unconditionally)
>   H3 token/API misuse               — ELIMINATED (422-custom, not 401/403;
>      docs confirm request shape + 201/204 handling correct)
> Fix: isRepoOwner() guard — owner buys → fulfilled, no invite. Regression
>   test fails before, passes after; control test pins normal buyers to 1 invite.
> Sibling sweep: refund bot already guards the same case; a dead duplicate
>   core file (drift hazard) flagged for deletion; the deeper debt — ANY
>   failure is terminal because processed.push runs in the catch path, so a
>   transient 5xx never retries. Named for a deliberate decision.
> ```

**`crew-planner`: options, then a plan.** For tasks where the approach itself
is a decision. Recon in the codebase first, 2-3 genuinely different options
with the rejected one and why, then steps sized by risk (every step with an
observable done-check), and the section that matters most: explicit non-goals.

### Skills (disciplines you invoke inline)

**`crew-verify`: evidence before claims.** The gate between finishing work
and describing work. Turns each claim ("fixed", "passing", "works") into the
cheapest observation that would prove it, made *this session*, and includes
the trick most setups miss: verify the verifier (green that can't go red is
not evidence). Then it runs the other half nobody runs: the claims your change
just *falsified* somewhere else, the counts and READMEs and screenshots no test
covers. Anything unobserved ships labeled "changed, not verified".

**`crew-scope`: size first, then plan that much.** S/M/L sizing by counting
plausible designs, a 5-line mini-plan for M tasks (every line objection-bait),
dispatch the planner for L. Kills both failure modes: coding an L blind, and
planning theater on an S. Plus the mid-task rule for "while I'm here" creep:
park it, don't chase it.

**`crew-git`: history as a communication act.** Atomic commits tested by
"can this revert alone", the staged-diff read-through (the medium switch that
catches debug prints), why-not-what messages, and a safe-repair table,
including the rule that matters when it matters: a leaked secret is *rotated
first*; history rewriting is only tidying.

Every transcript in this README is a recorded session. There are no
illustrative examples here, because an invented transcript proves only that we
can write one. The three skills above ship without a sample for an honest
reason: a skill is a discipline you invoke inline rather than an agent that
reports, so there is no artifact to record that would not be staged.

Two further recorded runs, including a paid agent and the free reviewer working
the same public commit, are in
[SAMPLES.md](SAMPLES.md#5-a-real-run-free-and-paid-on-the-same-public-commit).

## Free vs full

This repo is the free tier, and it's genuinely useful alone. The full pack is
the whole system: ten agents and fourteen skills that cross-reference each
other, plus hooks and starter templates.

**Before deciding, read [SAMPLES.md](SAMPLES.md).** A paid prompt pack is the
one kind of product you cannot evaluate before paying, so that page opens it:
the complete text of one paid agent and one paid skill, the `description` of
all eighteen paid-only files, the exact `diff` between the six free files and
their paid counterparts, a recorded run of a free and a paid agent on the same
public commit (including the live bug it found), and our own account of the
three weakest files in the pack.

| | Crew (this repo) | [Crew Full ($19)](https://honorboxx.github.io/honorbox/crew.html) |
|---|---|---|
| Agents | 3: reviewer, debugger, planner | 10: + simplifier (second review pass), tester, perf, security, refactorer, docs, release captain |
| Skills | 3: verify, scope, git | 14: + TDD, debug loop, self-review, PR authoring, changelog, release, docs pass, refactor, perf triage, security pass, handoff |
| Hook examples | none | 6, safe and commented (git, shell, exfil, scope and secret guards, plus format-on-edit), with their test suites |
| CLAUDE.md starter templates | none | solo + team variants |
| Design doc | none | ROSTER.md: every agent/skill mapped to a job and a boundary |
| Installer | this one | same one, covering the full pack |
| Updates | `git pull` | private repo access; updates land there |
| License | MIT | per-developer commercial |

Buying replaces the six free files with superset versions (added
cross-references into the full system). The installer handles it cleanly, and
[the exact diff is published](SAMPLES.md#1-what-buying-changes-about-the-files-you-already-have)
so you can see precisely what changes before you pay.

## Honest limits

- These improve *discipline*, not model capability. A model that can't find a
  bug won't find it because a prompt told it to be systematic, but it will
  stop claiming "fixed" without running the repro.
- Agents inherit your configured model and burn tokens like any subagent;
  the reviewer pass on a big diff is not free.
- Written for Claude Code's agent/skill format. Other tools may read the
  markdown fine, but the dispatch/invoke mechanics are Claude Code's.

## License

MIT. See [LICENSE](LICENSE).
