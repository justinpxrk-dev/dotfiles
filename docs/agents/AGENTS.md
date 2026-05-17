# AGENTS.md

Guidance for coding agents when working in this repository.

## Project Overview

Personal macOS dotfiles managed with [chezmoi](https://chezmoi.io). The repo root is `~/.local/share/chezmoi/`. Chezmoi naming conventions map files to their target locations:

- `dot_` prefix → dotfile (e.g. `dot_config/` → `~/.config/`)
- `executable_` prefix → file is made executable on apply

## Project Structure

Both `dot_config/` and `Library/` are applied by chezmoi; all other directories are tracked in git only.

```
chezmoi/
├── dot_config/ → ~/.config/
│   ├── borders/
│   ├── ghostty/
│   ├── git/
│   ├── nvim/
│   ├── sketchybar/
│   │   └── lib/
│   │       ├── SbarLua @
│   │       └── sketchybar-app-font @
│   ├── spicetify/
│   ├── yabai/
│   └── zsh/
├── Library/    → ~/Library/
│   └── LaunchAgents/
├── Scripts/    — shell scripts
├── Themes/     — Petrichor theme definitions (see Themes System)
│   └── lib/
│       ├── tinted-terminal @ ⑂
│       └── tinted-vscode @ ⑂
├── Wallpapers/ — desktop wallpapers
├── Assets/     — icons and images
├── Fonts/      — font sources
│   ├── font-monolisa @ †
│   └── lib/
│       └── monolisa-nerdfont-patch @ †
├── docs/       — documentation
├── .chezmoiscripts/ — bootstrap scripts run automatically by chezmoi on apply
├── .claude/    — Claude Code config and skills
│   └── skills/ — custom slash commands
├── .vscode/    — VSCode workspace settings
└── Unmanaged/  — reference configs not managed by chezmoi
```

`@` submodule · `⑂` fork · `†` private

## Chezmoi Workflow

```sh
chezmoi diff                          # Preview changes before applying
chezmoi apply                         # Apply all managed files to home dir
chezmoi apply ~/.config/sketchybar    # Apply a specific path
```

## Formatting and Linting

Tools are managed via `mise` (node, pnpm, python, ruff, rust, stylua, lua-language-server). Run `mise install` first.

```sh
pnpm run format          # Format all (Markdown via prettier, shell via shfmt, Lua via stylua, Python via ruff)
pnpm run format:check    # Check formatting without writing
pnpm run lint            # Lint shell (shellcheck), Lua (lua-language-server), and Python (ruff, pyright)
```

Individual formatters:

```sh
pnpm run format:md / format:sh / format:lua / format:py
pnpm run lint:sh / lint:lua / lint:py
```

## Scripts

If you need details about available scripts, read `docs/scripts.md`.

## Zsh Config

Config lives in `dot_config/zsh/`, split across several files:

- `dot_zshrc` — main init; sources all other files and loads plugins via antidote
- `dot_zshrc_env.tmpl` — all environment variables (XDG, PATH, Homebrew, gpg, neovim, uv, mise, etc.)
- `dot_zshrc_aliases` — CLI tool replacements, editor shortcuts, and shell conveniences
- `dot_zshrc_bindings` — keybindings
- `dot_zshrc_evals` — cached eval statements via evalcache (Homebrew, mise)
- `dot_zshrc_hooks` — zsh hooks (precmd, preexec)
- `dot_zshrc_opts` — zsh options (history, directory, misc)
- `dot_zsh_plugins.txt` — antidote plugin list

## Conventions

Standard conventions to follow when making changes.

### Comments and Documentation

Write documentation comments on all functions, classes, and modules — describe purpose, parameters, and return values using language-appropriate syntax (e.g. `---` annotations in Lua, docstrings in Python).

Write inline comments for non-obvious *why* — hidden constraints, invariants, workarounds, or behavior that would surprise a reader. Do not describe what the code does; well-named identifiers already do that.

After any change, update all relevant documentation to reflect the new state — `docs/agents/AGENTS.md`, other files in `docs/`, and any READMEs.

## Rules

These rules that must be followed. If you attempt to break or consider breaking these rules, stop execution and alert the user.

- Always commit using the `/commit` skill — never run `git commit` directly.
- Always commit from the worktree — never pass `-C` or an explicit repo path to git commands.
