---
name: crew-scope
description: Use at the start of any coding task, before writing code. Sizes the task (S/M/L) and produces the right amount of plan: nothing, a 5-line mini-plan, or a dispatched planner. Also the tool against mid-task scope creep.
---

# crew-scope: size first, then plan that much

The expensive failure isn't messy code; it's building the wrong thing well.
The cheap insurance is proportional: most tasks deserve five lines of plan,
a few deserve none, and a few deserve a real one. Oversized planning is its
own failure (planning theater); this skill picks the size.

## The sizing test

Count the *plausible designs*, not the lines of code:

- **S:** one obvious way to do it, blast radius one or two files. Just do it.
  (A one-line fix in a payment path is NOT S: blast radius outranks size.)
- **M:** one approach, several files; or any task where you paused to think
  "hmm, where should this live?". Write the 5-line mini-plan below, in the
  conversation, before code.
- **L:** two or more genuinely different approaches exist, or the done
  condition is fuzzy, or it touches schema/public API/money. Dispatch
  `crew-planner` (or write a real plan yourself if dispatching is
  unavailable) and get the options question settled before any code.

A second test, for the done condition: if you can't state in one sentence how
you'll *know* the task is finished, it isn't scoped yet. Keep asking "how
will we know?" until that sentence exists. That sentence later becomes the
verification target, so writing it now is not overhead, it's prepayment.

## The 5-line mini-plan (M tasks)

    Goal: <the one-sentence done condition>
    Touches: <files/modules you expect to change>
    Approach: <one sentence, enough for someone to object to>
    Risk: <the thing most likely to bite, and how you'll notice early>
    Non-goal: <the adjacent thing you are deliberately NOT doing>

Thirty seconds to write. Its value is that every line is objection-bait: a
wrong `Touches:` line gets corrected now instead of at review.

## Scope creep: the mid-task rule

"While I'm here" is how an M task becomes an L task nobody approved. When you
notice adjacent work (a refactor begging to happen, a second bug, a missing
test elsewhere): park it in a follow-ups list and finish the scoped task.
The parked list at the end is a *feature* of your report, not an admission of
laziness. Exception: adjacent work that blocks correct completion of the
current task isn't creep. It's discovered scope; resize honestly (M→L) and
say so before continuing.

## Failure modes

| Smell | Correction |
|---|---|
| Mini-plan for renaming a variable | That's planning theater; S tasks skip straight to work |
| "I'll figure out the design as I code" on an L | The design decisions still get made, just silently and worse |
| Questions to the user the codebase can answer | Recon first; ask only what `grep` cannot resolve |
| Done condition = "improve X" | Not a done condition; find the observable |
| Third "while I'm here" this task | Stop; resize or park |
