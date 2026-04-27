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
└── Unmanaged/  — reference configs not managed by chezmoi
```

`@` git submodule · `⑂` fork · `†` private

## Chezmoi Workflow

```sh
chezmoi diff                          # Preview changes before applying
chezmoi apply                         # Apply all managed files to home dir
chezmoi apply ~/.config/sketchybar    # Apply a specific path
```

## Formatting and Linting

Tools are managed via `mise` (node, pnpm, stylua, lua-language-server). Run `mise install` first.

```sh
pnpm run format          # Format all (Markdown via prettier, shell via shfmt, Lua via stylua)
pnpm run format:check    # Check formatting without writing
pnpm run lint            # Lint shell (shellcheck) and Lua (lua-language-server)
```

Individual formatters:

```sh
pnpm run format:md / format:sh / format:lua
pnpm run lint:sh / lint:lua
```

## Zsh Config

Config lives in `dot_config/zsh/`, split across four files:

- `dot_zshrc` — main init; sources the other three files and loads plugins via zinit
- `dot_zshrc_paths` — PATH and tool env vars (Homebrew, goenv, gpg, neovim, uv, mise, etc.)
- `dot_zshrc_aliases` — CLI tool replacements, editor shortcuts, and shell conveniences
- `dot_zshrc_evals` — cached eval statements via evalcache (goenv, Homebrew, mise)
