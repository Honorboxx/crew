---
name: crew-verify
description: Use before claiming any work is done, fixed, working, or passing, and before committing or opening a PR. Converts each claim you're about to make into observed evidence from this session, and downgrades anything unproven to "changed but unverified".
---

# crew-verify: evidence before claims

The words "done", "fixed", "works", "passing", "verified" are claims about the
world, and reading code is not observing the world. This skill is the gate
between finishing the work and describing the work.

## The method: verification is claim-shaped

You don't "verify the code"; you verify *claims*. So start from the words,
not the diff:

1. Write down the claims you are about to make, as bullet points, in the
   words you'd actually use ("the flag parser now accepts `--target`",
   "the crash is fixed", "docs match the new behavior").
2. For each claim, name the cheapest observation that would prove it. Then
   go make that observation, this session.
3. Anything you can't or didn't observe gets reported as exactly that:
   "changed, not verified", with the reason. Under-claiming costs a
   sentence; over-claiming costs the reader's trust and a broken deploy.

## Minimum evidence per claim

| Claim | Floor of evidence (observed this session) |
|---|---|
| "it compiles / builds" | the build command's actual output, exit 0 |
| "tests pass" | test run output with counts, and the tests exercise the change |
| "the bug is fixed" | repro failing before the fix, passing after (both outputs) |
| "feature works" | the real entry point exercised end-to-end, not only a unit harness |
| "UI looks right" | rendered output actually seen (screenshot, curl of the page) |
| "faster now" | before/after numbers, same machine, same workload |
| "docs are updated" | every changed command re-run as written |
| "nothing else broke" | the affected test suite run, not asserted |

## Verify the verifier

The most seductive false pass: tests that pass because they never touched the
change. When a test run is your evidence, confirm the connection. Break the
change deliberately for one run (or check coverage/logs) and watch the test
fail, then restore. Green that can't go red is not evidence. Same for the
environment: confirm you ran the built artifact, current branch, fresh build.
Anything "verified" against a stale binary is the classic self-own.

## The claims your change just falsified

Everything above checks whether the claims you are *making* are true. The other
half is the claims already written down that your change just made false. These
never fail a build, no test covers them, and they are read by the people you
most want to trust you.

They are also the most common way a verified change still ships a lie. A README
that says the page loads no JavaScript, written before you added a toggle. A
count in a doc, correct until you added the fourth item. A screenshot showing
the old copy. A comment describing the branch you just deleted.

Between finishing and reporting, ask: **what did this change make untrue
somewhere else?** Then grep for it rather than trying to remember.

| You changed | Go grep for |
|---|---|
| Added, removed or renamed a thing in a set | the count of that set, spelled out and numeric, and any list naming the members |
| Behavior a doc describes | that doc's claim, and the quickstart that walks through it |
| Anything user-visible | screenshots, recorded sessions, sample output, social-card images |
| A flag, command or path | every place it appears outside code: README, help text, comments, other repos |
| A default | the sentence somewhere that says what the default is |

Two rules that make this cheap:

- **Grep for the claim, not the code.** The stale sentence rarely contains the
  identifier you changed. Search the number, the adjective, the old name.
- **Fix it in the same commit.** A follow-up commit for stale docs is a commit
  that does not get made, and the gap between them is when someone reads it.

The trap worth naming: fixing a stale claim is itself a change, so it can
falsify a neighbouring claim in turn. Correcting a count, then leaving the same
count wrong two paragraphs down, is the usual shape. Re-grep after the fix.

## Failure modes

| Trap | Reality |
|---|---|
| "The change is trivial, no need to run it" | Trivial changes have the least-reviewed blast radius; run it anyway |
| "I verified the change, so I'm done" | You verified your claims; you did not check the claims your change falsified elsewhere |
| Verifying via the harness only | Users run the entry point; the harness skips the wiring where bugs live |
| "Tests pass" (they didn't run the new path) | See *verify the verifier* |
| Declaring victory from logs you expected | Search for the failure signal too, not just the success line |
| Verifying once, then "one last tweak" | Any edit after verification voids it; re-run the cheapest relevant check |

## Definition of done

The claims list exists; every claim carries its observation (command + real
output, quoted, not summarized); everything unobserved is explicitly labeled
unverified; and the claims this change falsified elsewhere are found and fixed
in the same commit. Then, and only then, write the report or the commit
message.
