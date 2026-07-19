---
name: crew-git
description: Use whenever committing, branching, or repairing git history — enforces atomic commits, the staged-diff read-through, honest messages, and the safe-repair table (including the rotate-first rule for leaked secrets).
---

# crew-git — history as a communication act

A commit is not a save point; it's the unit someone else reviews, bisects,
reverts, and reads in `git blame` three years from now. Hygiene here is not
tidiness — it's making every one of those four operations work.

## Committing

- **One logical change per commit.** The operational test isn't "is it small"
  but "can it be reverted alone without collateral damage". Mechanical noise
  (rename, format, lockfile churn) goes in its own commit, separated from
  behavior — a reviewer can wave through a pure-rename commit in seconds *if*
  it's pure, and `git bisect` stays sharp.
- **Read the staged diff before every commit.** `git diff --staged`, every
  hunk, in the terminal — the medium switch from your editor resets
  pattern-blindness. This is where debug prints, stray files, commented-out
  code, and "how did THAT get staged" are caught. Stage deliberately
  (`git add -p` when the tree is mixed), never `git add -A` out of habit.
- **Message = why, not what.** The diff already says what. Imperative subject
  ≤ 72 chars; body for the why, the alternative you rejected, and any
  non-obvious consequence. If the subject needs "and", split the commit.
- Never commit: secrets, generated files the repo doesn't already track,
  half-done work on a shared branch. `WIP` commits are fine on your own
  branch *if* they're squashed before review.

## Branching

Branch per task, from up-to-date main. Never commit to main by habit — if
the repo allows it, that's the repo being polite, not it being a good idea.
Rebase your own unshared branch to stay current; **never rewrite anything
already pushed to a branch others use.** Whether the repo merges or rebases
onto main is the repo's convention, not yours to relitigate mid-PR.

## Safe repair table

| Situation | Repair |
|---|---|
| Committed too soon, not pushed | `git commit --amend` / `git rebase -i` freely |
| Committed too soon, already pushed to shared branch | New commit on top; amending pushed history transfers your mistake to everyone's clone |
| Wrong branch | `git cherry-pick` onto the right one, then remove from the wrong one |
| Need to undo a pushed commit | `git revert` — an honest new commit, history intact |
| Staged/tracked file that must never be | remove + `.gitignore` in the same commit, or it returns |
| **Secret committed** | **Rotate the secret FIRST.** History rewriting comes second and only for tidiness — clones, forks, and CI logs already have the value, so scrubbing without rotating is theater |
| Detached HEAD / "everything is gone" | `git reflog` — it's almost never gone; find the SHA, branch from it |

## Failure modes

| Habit | Cost |
|---|---|
| `git add -A && git commit -m fix` | Unreviewable history; bisect finds "fix" |
| Force-push to a shared branch | Everyone downstream rebases their morning away |
| Mixing rename + logic in one commit | Reviewer must diff-in-head the rename to see the logic |
| Amending as amnesia (repeatedly rewriting local history mid-debug) | You destroy the trail `git bisect` needed |
| Commit message novel for a typo fix | Effort budget spent where nobody needed it |
