---
description: Merge a worktree branch into main. Rebases the branch onto main, fast-forward merges it, then asks whether to delete the branch and remove its worktree. Usage: /merge <branch-name>
---

Merge a branch into main by rebasing it onto main and fast-forward merging it.

## Steps

1. **Verify preconditions** — confirm the current branch is `main`. If not, stop and tell the user.

2. **Identify the branch** — use the branch name passed as the skill argument. If no argument was given, ask the user which branch to merge.

3. **Confirm the branch exists** — run `git branch --list <branch>`. If it doesn't exist, stop and tell the user.

4. **Rebase onto main** — run `git rebase main <branch>`. This checks out the branch and replays its commits on top of the current main.
   - If the rebase fails due to conflicts, run `git rebase --abort` to restore the branch to its pre-rebase state, then report which files conflicted and stop. Do not attempt to resolve conflicts.

5. **Return to main** — run `git switch main`.

6. **Fast-forward merge** — run `git merge --ff-only <branch>`.
   - If this fails (should be impossible after a clean rebase, but guard anyway), report the error and stop without leaving main in a dirty state.

7. **Report success** — show a one-line summary: branch name, number of commits landed, and the new HEAD sha.

8. **Offer cleanup** — ask the user: "Delete branch `<branch>` and remove its worktree?" If yes:
   - Find the worktree path for this branch: `git worktree list --porcelain | grep -A1 "branch refs/heads/<branch>"` — extract the `worktree` path from the output.
   - If a worktree exists, remove it first: `git worktree remove <path>`.
   - Then delete the branch: `git branch -d <branch>`.
   - If no worktree is found, just delete the branch.

## Rules

- Never force-push or use `--force` flags.
- Never skip the fast-forward check — if `--ff-only` fails, stop and report.
- Never proceed past a failed rebase — always abort first.
- Always end on the `main` branch regardless of success or failure.
