# AGENTS.md

Guidance for coding agents when working in this repository.

## Project Overview

Personal macOS dotfiles managed with [chezmoi](https://chezmoi.io). The repo root is `~/.local/share/chezmoi/`. Chezmoi naming conventions map files to their target locations:

- `dot_` prefix → dotfile (e.g. `dot_config/` → `~/.config/`)
- `executable_` prefix → file is made executable on apply

## Project Structure

Entries prefixed with `dot_` or `empty_`, and `Library/`, are applied by chezmoi; all other directories are tracked in git only.

```
chezmoi/
├── .chezmoiscripts/ — bootstrap scripts run automatically by chezmoi on apply
├── .claude/    — Claude Code config and skills
│   └── skills/ — custom slash commands
├── .vscode/    — VSCode workspace settings
├── docs/       — documentation
├── dot_Brewfile          → ~/.Brewfile
├── dot_claude/           → ~/.claude
├── dot_config/ → ~/.config/
│   ├── borders/
│   ├── ghostty/
│   ├── git/
│   ├── nvim/
│   ├── sketchybar/
│   │   └── lib/
│   │       ├── sketchybar-app-font @
│   │       └── SbarLua @
│   ├── skhd/
│   ├── spicetify/
│   ├── yabai/
│   └── zsh/
├── dot_zshenv.tmpl       → ~/.zshenv
├── empty_dot_hushlogin   → ~/.hushlogin
├── Assets/     — icons and images
├── Fonts/      — font sources
│   ├── font-monolisa @ †
│   └── lib/
│       └── monolisa-nerdfont-patch @ †
├── Library/    → ~/Library/
│   └── LaunchAgents/
├── Scripts/    — shell scripts
├── Themes/     — Petrichor theme definitions (see Themes System)
│   └── lib/
│       ├── tinted-shell @ ⑂
│       ├── tinted-terminal @ ⑂
│       └── tinted-vscode @ ⑂
├── Unmanaged/  — reference configs not managed by chezmoi
└── Wallpapers/ — desktop wallpapers
```

`@` submodule · `⑂` fork · `†` private

## Chezmoi Workflow

```sh
chezmoi diff                          # Preview changes before applying
chezmoi apply                         # Apply all managed files to home dir
chezmoi apply ~/.config/sketchybar    # Apply a specific path
```

## Developer Workflow

See [`docs/developer.md`](../developer.md) for setup, formatting, linting, and worktree tool lifecycle (e.g. `mise trust`).

## Scripts

Scripts live under `Scripts/` and are all available as mise tasks. Run `mise tasks` to list them or `mise run <task>` to invoke one (e.g. `mise run themes:build -- petrichor-dark`). For full per-script documentation, read `docs/scripts.md`.

## Zsh Config

`dot_zshenv.tmpl` → `~/.zshenv` is sourced for all shells (interactive, non-interactive, login). `dot_config/zsh/` contains files sourced only for interactive shells:

- `dot_zshrc` — main init; sources all other files and loads plugins via antidote
- `dot_zshrc_env` — interactive-only environment variables (zsh dirs)
- `dot_zshrc_aliases` — CLI tool replacements, editor shortcuts, and shell conveniences
- `dot_zshrc_bindings` — keybindings
- `dot_zshrc_evals` — cached eval statements via evalcache (Homebrew, mise)
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

- **Docs:** `docs/agents/AGENTS.md`, other files in `docs/`, READMEs
- **Ignore files:** `.gitignore`, `.prettierignore`, `.chezmoiignore`, `.shfmtignore`, `.styluaignore`
- **Formatter / linter configs:** `pyproject.toml`, `dot_config/nvim/.luarc.json`, `dot_config/sketchybar/.luarc.json`
- **Tool scripts:** `package.json` (pnpm lint/format scripts), `mise.toml` (tool versions)

## Rules

These rules that must be followed. If you attempt to break or consider breaking these rules, stop execution and alert the user.

- Always commit using the `/commit` skill — never run `git commit` directly.
- Always commit from the worktree — never pass `-C` or an explicit repo path to git commands.
