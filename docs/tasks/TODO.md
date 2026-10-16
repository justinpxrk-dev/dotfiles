# TODO

## High Priority

- [ ] Configure workflows/deploy-authenticated-macos to test successful clone of private repositories.

## Medium Priority

- [ ] Integrate `chezmoi` with `bitwarden-cli` for SSH key access.
- [ ] Replace user-specific paths (.zshenv, .zshrc_env, Library/LaunchAgents/) with `chezmoi` templates.

## Low Priority

- [ ] Configure macos system settings script.
- [ ] Harden bootstrap PATH: `dot_scripts/brew/executable_install-packages.sh` and `dot_scripts/git/executable_install-submodules.sh` call bare `brew`/`mise`, assuming Homebrew is already on `PATH`; a cold-start `chezmoi init --apply` (before the shell profile exists) can fail. Add absolute-path `eval "$(/opt/homebrew/bin/brew shellenv)"` (as in `dot_scripts/luarocks/executable_install-rocks.sh`) so they work before `PATH` is set up.
- [ ] Write comment headers for all zsh, lua.
- [ ] Write type annotations for all lua.
