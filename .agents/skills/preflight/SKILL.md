---
name: preflight
description: Scan documentation for staleness and format/auto-fix the working tree so a commit passes the pre-commit hook cleanly. Use when the user wants to "preflight", prep the tree, or get ready to commit. Automatically invoked by /commit.
---

# Preflight — pre-commit preparation

Scan documentation for staleness and format/auto-fix the working tree so a commit goes out clean. The lefthook **pre-commit hook** (`format:check` + `lint`, run in parallel) is the authoritative gate and fires on every commit — preflight prepares the tree so that gate passes; it does not duplicate it.

## Steps

Run in order. All tools are mise-managed — prefix commands with `mise exec --` if they are not on PATH (always the case in a fresh worktree).

1. **Documentation scan.** Compare `git status --short` and `git diff` against docs that could now be out of date, and propose specific edits (show the new wording or a diff) for each. Per `AGENTS.md` "Keeping Config in Sync":
   - `.agents/memories/AGENTS.md` — project structure, conventions, rules
   - `docs/**` (developer.md, scripts.md, ops/\*) and any README
   - Ignore files — `.gitignore`, `.prettierignore`, `.chezmoiignore`, `.styluaignore`, and the `ignores` list in `.markdownlint-cli2.jsonc`
   - Editor / formatter / linter configs — `.editorconfig`, `pyproject.toml`, `dot_config/nvim/.luarc.json`, `dot_config/sketchybar/.luarc.json`
   - Tool manifests — `package.json` (pnpm scripts), `mise.toml` (tool versions)
   - `.agents/skills/**/SKILL.md` — if a workflow described there has changed

   **Ask the user to approve before applying.** Apply only what's approved.

2. **Format & auto-fix.** Run `pnpm fix` (`lint:fix` then `format`) so the tree — including any doc edits from step 1 — will pass the pre-commit hook. Show the user what it rewrote.

3. **Report** — which docs were updated and which files the formatter / linter rewrote (so the user knows their working tree changed).

## Rules

- The doc scan is a proposal step: never edit docs without explicit approval.
- Never bypass the pre-commit hook — no `--no-verify`. Non-auto-fixable lint (shellcheck, `pyright`, `lua-language-server`) is enforced by the hook at commit time; if it fails there, fix the issue and commit again.
- Safe to run standalone (e.g. before opening a PR or running `chezmoi apply`), not just from `/commit`. Run `pnpm check` directly for the full lint/format gate without committing.
