---
name: commit
description: Write a git commit following this repo's conventions. Use when the user wants to "commit", "make a commit", or asks you to write a commit message. Runs /preflight first, then commits without pausing for confirmation.
---

# Commit — write a commit in this repo's style

Stage the intended changes and write a commit message that matches this repo's conventions. This is a chezmoi dotfiles repo; commit from the worktree, never with `-C` or an explicit repo path. Invoking `/commit` is the go-ahead — don't pause to confirm the message; draft it, commit, and show what landed.

## Steps

1. **Run `/preflight` first.** Invoke the `preflight` skill to scan docs for staleness (apply approved edits) and format/auto-fix the tree. If the user declines a proposed doc update, stop and resolve before continuing. This step is mandatory — never skip it. (The lefthook pre-commit hook runs the authoritative `format:check` + `lint` gate when you commit in step 5.)
2. Run `git status --short`, `git diff --staged`, and `git diff` (unstaged) in parallel to see everything that's changing — including anything preflight rewrote.
3. Stage the intended changes explicitly by name — never blanket `git add -A` / `git add .` (avoids sweeping in secrets, large binaries, or unrelated work). Pause to ask only if the change set looks unrelated or risky.
4. Draft a message following the format below.
5. Commit it via heredoc — don't wait for approval; just show the message you're committing. The quoted `<<'EOF'` keeps the multi-line message intact and unexpanded (`$`, backticks, etc.):

   ```sh
   git commit -m "$(cat <<'EOF'
   <message>
   EOF
   )"
   ```

6. Run `git status` to confirm, and report the result (sha + subject).

## Format

### Subject line

`type(scope?): subject`

- **Types:** `feat`, `fix`, `docs`, `refactor`, `chore`, `ci`, `test`. Use `chore(deps)` for routine dependency bumps, or `fix(deps)` when the bump patches a vulnerability.
- **Scope** (optional): the tool or area touched — e.g. `zsh`, `nvim`, `sketchybar`, `git`, `brew`, `skills`, `ci`, `chezmoi`.
- Imperative mood, lowercase after the colon, no trailing period. Keep under ~70 chars.

### Body

- **Omit entirely** for trivial one-liners.
- Otherwise: blank line after subject, then bullets (`-`) or short paragraphs wrapped at ~72 chars.
- Explain **why**, not what — design rationale, upgrade hazards, security context, links to upstream advisories or issues.

### Examples

```text
chore(brew): add lazygit terminal git ui
```

```text
fix(deps): force patched js-yaml for merge-key dos

- Pin js-yaml via pnpm overrides to the patched release
- Resolves the Dependabot advisory for prototype pollution on merge keys
```

## Rules

- **Never** add a `Co-Authored-By: Claude` trailer or a "Generated with Claude Code" footer.
- **Never** use emojis in the subject or body.
- **Never** `--no-verify` — if the lefthook pre-commit hook fails, fix the underlying issue and commit again.
- **Never** `--amend` unless the user explicitly asks. Make a new commit instead.
- **Never** stage with `git add -A` / `git add .` — name files explicitly.
- Always run `/preflight` first. Don't pause for message confirmation — invoking `/commit` is the go-ahead; surface the committed message in your reply.
