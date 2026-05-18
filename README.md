# dotfiles

## Health Check

| CI                                                                                                                                                          | Deploy (public)                                                                                                                                                                                | Deploy (authenticated)                                                                                                                                                                                              |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![CI](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/ci.yml) | [![Deploy (public)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-public.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-public.yml) | [![Deploy (authenticated)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-authenticated.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-authenticated.yml) |

macOS dotfiles managed by [`chezmoi`](https://www.chezmoi.io/).

<img src="Assets/screenshots/terminal-petrichor-dark.png" width="100%" />

## Bootstrap

On a new machine, install `chezmoi` and apply the dotfiles in one step:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply justinpxrk-dev
```

Or if `chezmoi` is already installed:

```sh
chezmoi init --apply justinpxrk-dev/dotfiles
```

`chezmoi` automatically runs bootstrap scripts on first apply (submodules, cargo tools, LaunchAgent registration). Afterwards, apply macOS system defaults and reboot:

```sh
./Scripts/macos/set_system_settings.sh    # apply macOS defaults (reboot after)
```

## Update

```sh
chezmoi update
```

## Structure

Entries prefixed with `dot_` or `empty_`, and `Library/`, are applied by `chezmoi`; all other directories are tracked in git only.

```
chezmoi/
├── .chezmoiscripts/ — bootstrap scripts run automatically by chezmoi
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
│       ├── tinted-terminal @ ⑂
│       └── tinted-vscode @ ⑂
├── Unmanaged/  — reference configs not managed by chezmoi
├── Wallpapers/ — desktop wallpapers
├── docs/       — documentation
├── dot_Brewfile → ~/.Brewfile
├── dot_claude/ → ~/.claude
├── dot_config/ → ~/.config/
│   ├── borders/
│   ├── chezmoi/
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
├── dot_zshenv  → ~/.zshenv
└── empty_dot_hushlogin → ~/.hushlogin
```

`@` submodule · `⑂` fork · `†` private
