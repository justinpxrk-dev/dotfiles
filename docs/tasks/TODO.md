# TODO

## High Priority

- Configure workflows/deploy-authenticated-macos to test successful clone of private repositories.
- Re-enable the `mas` App Store apps in `dot_Brewfile` (Copilot, Dynamic Wallpaper, Steam Link) — commented out because `mas` hangs in CI without App Store auth.

## Medium Priority

- Integrate `chezmoi` with `bitwarden-cli` for SSH key access.
- Replace user-specific paths (.zshenv, .zshrc_env, Library/LaunchAgents/) with `chezmoi` templates.

## Low Priority

- Configure macos system settings script.
- Harden bootstrap PATH: `scripts/brew/install-packages.sh` and `scripts/git/install-submodules.sh` call bare `brew`/`mise`, assuming Homebrew is already on `PATH`; a cold-start `chezmoi init --apply` (before the shell profile exists) can fail. Add absolute-path `eval "$(/opt/homebrew/bin/brew shellenv)"` (as in `scripts/luarocks/install-rocks.sh`) so they work before `PATH` is set up.
- Write comment headers for all zsh, lua, python.
- Write type annotations for all lua.

## Theming

Wire the remaining apps into the generated Petrichor base24 theme system (`scripts/themes/generate_base24_palette.py`) instead of hand-maintained or hardcoded colors.

- **tmux** — status bar colors are hardcoded `colourNNN` values deliberately kept plain for the Petrichor Dark palette; wire them into the generated theme system (`dot_config/tmux/tmux.conf`).
- **borders** — `borders/handle-theme-change.sh` sets hardcoded hex (`0x997ead67` / `0x99ffffff`, etc.) per mode; derive `active_color`/`inactive_color` from the generated palette (`scripts/borders/handle-theme-change.sh`).
- **delta** — `themes/handle-theme-change.sh` writes `mode.gitconfig` with `features = zebra-dark|zebra-light`, whose default `map-styles` backgrounds are intentionally faint. Override `map-styles` with palette-derived backgrounds (or foreground colors) for visible move-block coloring (`scripts/themes/handle-theme-change.sh`).
