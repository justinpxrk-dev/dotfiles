# AGENTS.md

Guidance for coding agents when working in this repository. This file is the
single source of truth: repo-root `CLAUDE.md` and `AGENTS.md` are symlinks to it,
so both Claude Code and Codex read the same content.

## Project Overview

Personal macOS dotfiles managed with [chezmoi](https://chezmoi.io). The repo root is `~/.local/share/chezmoi/`. Chezmoi naming conventions map files to their target locations:

- `dot_` prefix → dotfile (e.g. `dot_config/` → `~/.config/`)
- `executable_` prefix → file is made executable on apply

## Project Structure

Entries prefixed with `dot_` or `empty_`, and `Library/Application Support/` and `Library/LaunchAgents/`, are applied by chezmoi; all other directories are tracked in git only.

```text
chezmoi/
├── .agents/    — shared agent config, read by Claude and Codex
│   ├── AGENTS.md — shared agent guidance (this file)
│   └── skills/ — shared skill bodies (commit, preflight)
├── .chezmoiscripts/ — bootstrap scripts run automatically by chezmoi on apply
├── .claude/    — Claude Code config; skills/ symlink into .agents/skills/
│   └── skills/ — symlinks to .agents/skills/ (commit, preflight)
├── .github/    — GitHub Actions workflows
│   └── workflows/
├── .zed/       — Zed project settings and tasks (git-only)
├── assets/     — icons and images
├── Library/    → ~/Library/
│   ├── Application Support/ — per-app data (applied)
│   │   └── zen/ — Zen Browser profile config; chrome css symlinks to Library/Themes/Catppuccin/zen @
│   ├── Fonts/  — font sources (git-only)
│   │   ├── font-monolisa @ †
│   │   └── lib/
│   │       └── monolisa-nerdfont-patch @ †
│   ├── LaunchAgents/
│   ├── Themes/ — theme definitions (git-only)
│   │   ├── Catppuccin/
│   │   │   ├── delta @
│   │   │   ├── ghostty @
│   │   │   ├── spicetify @ ⑂
│   │   │   └── zen @
│   │   └── tinted/ — tinted-builder template upstreams
│   │       └── tinted-shell @ ⑂
│   ├── Unmanaged/ — reference configs not managed by chezmoi (git-only)
│   └── Wallpapers/ — desktop wallpapers (git-only)
├── docs/       — documentation
│   └── ops/    — operational runbooks (upgrade hazards, couplings)
├── AGENTS.md             → .agents/AGENTS.md (symlink — Codex entry point)
├── CLAUDE.md             → .agents/AGENTS.md (symlink — Claude entry point)
├── dot_Brewfile          → ~/.Brewfile
├── dot_claude/           → ~/.claude
├── dot_config/ → ~/.config/
│   ├── borders/
│   ├── chezmoi/
│   ├── delta/ — themes/catppuccin.gitconfig symlinks to Library/Themes/Catppuccin/delta @
│   ├── ghostty/ — themes/catppuccin-{mocha,latte}.conf symlink to Library/Themes/Catppuccin/ghostty @
│   ├── git/
│   ├── nvim/
│   ├── sketchybar/
│   │   └── lib/
│   │       ├── sketchybar-app-font @
│   │       └── SbarLua @
│   ├── skhd/
│   ├── spicetify/ — Themes/catppuccin symlinks to Library/Themes/Catppuccin/spicetify @ ⑂
│   ├── yabai/
│   ├── zed/
│   └── zsh/
├── dot_local/bin/        → ~/.local/bin — user-facing PATH commands (wrappers)
├── dot_scripts/          → ~/.scripts/ — shell scripts (applied)
├── dot_zshenv.tmpl       → ~/.zshenv
└── empty_dot_hushlogin   → ~/.hushlogin
```

`@` submodule · `⑂` fork · `†` private

## Chezmoi Workflow

```sh
chezmoi diff                          # Preview changes before applying
chezmoi apply                         # Apply all managed files to home dir
chezmoi apply ~/.config/sketchybar    # Apply a specific path
```

## Developer Workflow

See `docs/developer.md` for setup, formatting, linting, and worktree tool lifecycle (e.g. `mise trust`).

Define repository tasks in `mise.toml` and invoke them with `mise run`. Use pnpm to install and execute Node dependencies; keep workflow orchestration out of `package.json`.

## Scripts

Scripts are applied to `~/.scripts/` (source `dot_scripts/`, non-executable in the repo, `+x` on apply) ; run them by path (e.g. `~/.scripts/themes/handle-theme-change.sh`). For full per-script documentation, read `docs/scripts.md`.

User-facing scripts also get `~/.local/bin` PATH commands via thin `exec` wrappers: `handle-theme-change`, `handle-theme-change-spicetify`, `reload-launch-agent`, and `benchmark-startup`.

## Zsh Config

`dot_zshenv.tmpl` → `~/.zshenv` is sourced for all shells (interactive, non-interactive, login) and only holds shell-wide state that is safe to re-run in nested shells (XDG dirs, `ZDOTDIR`, `typeset -U PATH`). PATH manipulation lives in `.zprofile` so it does not compound across shell layers. `dot_config/zsh/` contains files sourced only by login/interactive shells:

- `dot_zprofile` — login-shell setup: PATH (Homebrew, sqlite, etc.) and `EDITOR`/`VISUAL`. Subshells inherit the exported env, so this only runs once per login.
- `dot_zshrc` — main init; sources all other files and loads plugins via antidote
- `dot_zshrc_env` — interactive-only environment variables (zsh dirs)
- `dot_zshrc_aliases` — CLI tool replacements, editor shortcuts, and shell conveniences
- `dot_zshrc_bindings` — keybindings
- `dot_zshrc_evals` — cached eval statements via evalcache (Homebrew, mise, zoxide)
- `dot_zshrc_hooks` — zsh hooks (precmd, preexec)
- `dot_zshrc_opts` — zsh options and plugin config (history, directory, misc, plugins)
- `dot_zsh_plugins.txt` — antidote plugin list

## Conventions

Standard conventions to follow when making changes.

### Comments

Write documentation comments on all functions, classes, and modules — describe purpose, parameters, and return values using language-appropriate syntax (e.g. `---` annotations in Lua, docstrings in Python).

Write inline comments for non-obvious _why_ — hidden constraints, invariants, workarounds, or behavior that would surprise a reader. Do not describe what the code does; well-named identifiers already do that.

### Keeping Config in Sync

After any change, update all relevant files to reflect the new state:

- **Docs:** `.agents/AGENTS.md`, other files in `docs/`, READMEs — the project-structure tree is duplicated in `.agents/AGENTS.md` and `README.md`; update both together
- **Skills:** `.agents/skills/**/SKILL.md` (canonical; `.claude/skills/` are symlinks to these)
- **Ignore files:** `.gitignore`, `.prettierignore`, `.chezmoiignore`, `.styluaignore`, and the `ignores` list in `.markdownlint-cli2.jsonc`
- **Editor config:** `.editorconfig`
- **Formatter / linter configs:** `dot_config/nvim/.luarc.json`, `dot_config/sketchybar/.luarc.json`
- **Tool manifests:** `package.json` (Node dependencies), `mise.toml` (tool versions and repository tasks)

### Operational Notes

Version couplings, upgrade hazards, and manual maintenance steps that no test or lint enforces live in `docs/ops/` (e.g. `docs/ops/upgrade-hazards.md`). Record new ones there when you introduce them.

## Rules

These rules that must be followed. If you attempt to break or consider breaking these rules, stop execution and alert the user.

- Always commit using the `commit` skill (`/commit` in Claude, the `commit` skill in Codex) — it runs `/preflight`, stages explicitly, and drafts a conventional-commit message. Never run `git commit` directly outside the skill.
- Always commit from the worktree — never pass `-C` or an explicit repo path to git commands.
- Never add AI attribution — no "Generated with Claude Code" footers or `Co-Authored-By: Claude` trailers — in commits, PR descriptions, or any repo artifact.
