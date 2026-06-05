# TODO

## High Priority

There's nothing here yet!

## Medium Priority

- Integrate `chezmoi` with `bitwarden-cli` for SSH key access.
- Configure workflows/deploy-authenticated-macos to test successful clone of private repositories.
- Replace user-specific paths (.zshenv, .zshrc_env, Library/LaunchAgents/) with `chezmoi` templates.

## Low Priority

- Configure macos system settings script.
- Harden bootstrap PATH: `Scripts/brew/install_packages.sh` and `Scripts/git/install_submodules.sh` call bare `brew`/`mise`, assuming Homebrew is already on `PATH`; a cold-start `chezmoi init --apply` (before the shell profile exists) can fail. Add absolute-path `eval "$(/opt/homebrew/bin/brew shellenv)"` (as in `Scripts/luarocks/install_rocks.sh`) so they work before `PATH` is set up.
- Rename scripts to be more concise, imperative, and kebab-case
- Write comment headers for all zsh, lua, python.
- Write type annotations for all lua.

## Theming

Wire the remaining apps into the generated Petrichor base24 theme system (`Scripts/Themes/generate_base24_palette.py`) instead of hand-maintained or hardcoded colors.

- **tmux** — status bar colors are hardcoded `colourNNN` values deliberately kept plain for the Petrichor Dark palette; wire them into the generated theme system (`dot_config/tmux/tmux.conf`).
- **borders** — `borders_apply_mode.sh` sets hardcoded hex (`0x997ead67` / `0x99ffffff`, etc.) per mode; derive `active_color`/`inactive_color` from the generated palette (`Scripts/Themes/borders_apply_mode.sh`).
- **delta** — `handle_theme_change.sh` writes `mode.gitconfig` with `features = zebra-dark|zebra-light`, whose default `map-styles` backgrounds are intentionally faint. Override `map-styles` with palette-derived backgrounds (or foreground colors) for visible move-block coloring (`Scripts/Themes/handle_theme_change.sh`).
