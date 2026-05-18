Merge a branch into main by rebasing it onto main and fast-forward merging it.

## Steps

1. **Verify preconditions** — confirm the current branch is `main`. If not, stop and tell the user.

2. **Identify the branch** — use the branch name passed as the skill argument. If no argument was given, ask the user which branch to merge.

3. **Confirm the branch exists** — run `git branch --list <branch>`. If it doesn't exist, stop and tell the user.

4. **Find the worktree path** — run `git worktree list --porcelain` and check if `branch refs/heads/<branch>` appears. If it does, extract the associated `worktree` path — you'll need it in steps 5 and 8.

5. **Check for uncommitted changes** — if the branch is checked out in a worktree, run `git status` from that worktree path. If there are any uncommitted or untracked changes, report them and stop. Do not proceed until the branch is clean.

6. **Rebase onto main**:
   - If the branch is checked out in a worktree: `cd` into the worktree path and run `git rebase main` there.
   - If the branch is not in a worktree: run `git rebase main <branch>` from the main working directory.
   - If the rebase fails due to conflicts, run `git rebase --abort` (from whichever directory the rebase was started), report which files conflicted, and stop. Do not attempt to resolve conflicts.

7. **Return to main working directory** — run `cd ~/.local/share/chezmoi` to ensure subsequent commands run from the correct location, not the worktree.

8. **Fast-forward merge** — run `git merge --ff-only <branch>`.
   - If this reports "Already up to date.", the branch had no unique commits — note this to the user but treat it as success.
   - If it fails for any other reason, report the error and stop.

9. **Report success** — show:
   - Branch name, number of commits landed (0 if already up to date), and the new HEAD sha.
   - A brief human-readable summary of what the changes do, inferred from commit messages and the diff.
   - A list of touched files from `git diff --name-only <previous-HEAD> HEAD`.

10. **Offer cleanup** — ask the user: "Delete branch `<branch>` and remove its worktree?" If yes:

- If a worktree path was found in step 4, remove it first: `git worktree remove <path>`.
- Then delete the branch: `git branch -d <branch>`.
- If no worktree was found, just delete the branch.

## Rules

- Never force-push or use `--force` flags.
- Never skip the fast-forward check — if `--ff-only` fails for a real reason, stop and report.
- Never proceed past a failed rebase — always abort first.
- Always end on the `main` branch regardless of success or failure.
- Always `cd` back to `~/.local/share/chezmoi` after any worktree operations — the shell working directory persists between tool calls.
- Always check for uncommitted changes before rebasing — never rebase a dirty worktree.
