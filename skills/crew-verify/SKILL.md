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

## Failure modes

| Trap | Reality |
|---|---|
| "The change is trivial, no need to run it" | Trivial changes have the least-reviewed blast radius; run it anyway |
| Verifying via the harness only | Users run the entry point; the harness skips the wiring where bugs live |
| "Tests pass" (they didn't run the new path) | See *verify the verifier* |
| Declaring victory from logs you expected | Search for the failure signal too, not just the success line |
| Verifying once, then "one last tweak" | Any edit after verification voids it; re-run the cheapest relevant check |

## Definition of done

The claims list exists; every claim carries its observation (command + real
output, quoted, not summarized); everything unobserved is explicitly labeled
unverified. Then, and only then, write the report or the commit message.
