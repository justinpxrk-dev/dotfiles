# TODO

## High Priority

- [ ] Configure workflows/deploy-authenticated-macos to test successful clone of private repositories.

## Medium Priority

- [ ] Integrate `chezmoi` with `bitwarden-cli` for SSH key access.
- [ ] Replace user-specific paths (.zshenv, .zshrc_env, Library/LaunchAgents/) with `chezmoi` templates.

## Low Priority

- [ ] Configure macos system settings script.
- [ ] Harden bootstrap PATH: `dot_scripts/brew/executable_install-packages.sh` and `dot_scripts/git/executable_install-submodules.sh` call bare `brew`/`mise`, assuming Homebrew is already on `PATH`; a cold-start `chezmoi init --apply` (before the shell profile exists) can fail. Add absolute-path `eval "$(/opt/homebrew/bin/brew shellenv)"` (as in `dot_scripts/luarocks/executable_install-rocks.sh`) so they work before `PATH` is set up.
- [ ] Write comment headers for all zsh, lua, python.
- [ ] Write type annotations for all lua.

## Theming

Wire the remaining apps into the generated Petrichor base24 theme system (`scripts/themes/generate_base24_palette.py`) instead of hand-maintained or hardcoded colors.

- [ ] **borders** — `borders/handle-theme-change.sh` sets hardcoded hex (`0x997ead67` / `0x99ffffff`, etc.) per mode; derive `active_color`/`inactive_color` from the generated palette (`scripts/borders/handle-theme-change.sh`).
