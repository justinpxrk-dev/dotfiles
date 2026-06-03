# dotfiles

## Health Check

| Format, Lint                                                                                                                                                                            | Deploy Public (macOS)                                                                                                                                                                                            | Deploy Authenticated (macOS)                                                                                                                                                                                                          | Zsh Benchmark Startup                                                                                                                                                                                                |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Format, Lint](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/format-lint.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/format-lint.yml) | [![Deploy Public (macOS)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-public-macos.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-public-macos.yml) | [![Deploy Authenticated (macOS)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-authenticated-macos.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/deploy-authenticated-macos.yml) | [![Zsh Benchmark Startup](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/zsh-benchmark-startup.yml/badge.svg)](https://github.com/justinpxrk-dev/dotfiles/actions/workflows/zsh-benchmark-startup.yml) |

_Intended for personal use. macOS dotfiles managed by [`chezmoi`](https://www.chezmoi.io/)._

<table width="100%">
	<tr>
		<th align="left">Desktop (<a href="https://catppuccin.com">Catppuccin Mocha</a>)</th>
	</tr>
	<tr>
		<td align="center"><img src="Assets/screenshots/Desktop-Catppuccin-Mocha.png" width="100%" alt="Desktop with the Catppuccin Mocha theme" /></td>
	</tr>
	<tr>
		<th align="left">Desktop (<a href="https://catppuccin.com">Catppuccin Latte</a>)</th>
	</tr>
	<tr>
		<td align="center"><img src="Assets/screenshots/Desktop-Catppuccin-Latte.png" width="100%" alt="Desktop with the Catppuccin Latte theme" /></td>
	</tr>
</table>

## Bootstrap

On a new machine, install `chezmoi` and apply the dotfiles in one step:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply justinpxrk-dev
```

Or if `chezmoi` is already installed:

```sh
chezmoi init --apply justinpxrk-dev/dotfiles
```

`chezmoi` automatically runs bootstrap scripts on first apply (submodules, LaunchAgent registration). Install developer environment and run setup scripts from the repo:

```sh
mise trust          # trust config file (mise.toml)
mise install        # install configured tools
mise themes:build   # build themes (rerun `chezmoi apply` to apply)
mise macos:settings # apply macOS defaults (reboot after)
```

To install theme for spotify:

```sh
spicetify backup apply
spicetify config current_theme petrichor-dark
spicetify apply
```

## Update

From the repo, `git pull` or from anywhere:

```sh
chezmoi update
```

## Structure

Entries prefixed with `dot_` or `empty_`, and `Library/`, are applied by `chezmoi`; all other directories are tracked in git only.

```text
chezmoi/                                — repo root (~/.local/share/chezmoi)
├── .chezmoiscripts/                    — bootstrap scripts run automatically by chezmoi on apply
├── .claude/                            — Claude Code config and skills
│   └── skills/                         — custom slash commands
├── .github/                            — GitHub metadata
│   └── workflows/                      — GitHub Actions workflows
├── Assets/                             — icons and images
├── Fonts/                              — font sources
│   ├── font-monolisa @ †               — MonoLisa font source (private)
│   └── lib/                            — font tooling
│       └── monolisa-nerdfont-patch @ † — Nerd Font patcher (private)
├── Library/                            → ~/Library/ - macOS Library files
│   └── LaunchAgents/                   — launchd service definitions
├── Scripts/                            — shell scripts (run via mise tasks)
├── Themes/                             — Theme definitions
│   └── lib/                            — theme template upstreams
│       ├── tinted-shell @ ⑂            — shell theme templates
│       ├── tinted-terminal @ ⑂         — terminal theme templates
│       └── tinted-vscode @ ⑂           — VSCode theme templates
├── Unmanaged/                          — reference configs not managed by chezmoi (Raycast, VSCode)
├── Wallpapers/                         — desktop wallpapers
├── docs/                               — documentation
├── dot_Brewfile                        → ~/.Brewfile - Homebrew bundle
├── dot_claude/                         → ~/.claude - Claude Code user config
├── dot_config/                         → ~/.config/ - XDG config root
│   ├── borders/                        — JankyBorders config
│   ├── chezmoi/                        — chezmoi config
│   ├── ghostty/                        — Ghostty terminal config
│   ├── git/                            — Git config
│   ├── nvim/                           — Neovim config
│   ├── sketchybar/                     — SketchyBar config
│   │   └── lib/                        — SketchyBar libraries
│   │       ├── sketchybar-app-font @   — app icon font
│   │       └── SbarLua @               — SketchyBar Lua bindings
│   ├── skhd/                           — skhd hotkey daemon config
│   ├── spicetify/                      — Spicetify (Spotify) config
│   ├── tmux/                           — tmux multiplexer config
│   ├── yabai/                          — yabai window manager config
│   └── zsh/                            — Zsh interactive shell config
├── dot_zshenv.tmpl                     → ~/.zshenv - Zsh environment (all shells)
└── empty_dot_hushlogin                 → ~/.hushlogin - suppress login banner
```

`@` submodule · `⑂` fork · `†` private
