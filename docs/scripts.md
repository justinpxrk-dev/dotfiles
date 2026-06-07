# Scripts

Scripts live under `scripts/` and are run from the repo root. All scripts are also available as mise tasks — run `mise tasks` for the full list, or `mise run <task>` to invoke one. Bootstrap scripts (`install-packages.sh`, `install-submodules.sh`, `install-rocks.sh`, `bootstrap-launch-agents.sh`) run automatically via chezmoi — manual invocation is only needed outside of `chezmoi apply`.

## `macos/set-system-settings.sh`

Applies macOS defaults and system preferences. Reboot immediately after — opening System Settings can overwrite changes, and some settings only take effect on reboot.

```sh
./scripts/macos/set-system-settings.sh
# or
mise run macos:set-system-settings
```

> Some settings, such as those in Location Services, cannot be scripted. Manually configured settings are documented in [manual-setup.md](macos-system-settings/manual-setup.md).

## `macos/bootstrap-launch-agents.sh`

Bootstraps all `me.justinpxrk.*` plists in `~/Library/LaunchAgents` into the current login session. Run automatically by chezmoi (`run_onchange_`) whenever the script changes.

```sh
./scripts/macos/bootstrap-launch-agents.sh
# or
mise run macos:bootstrap-launch-agents
```

## `git/install-submodules.sh`

Initialises all git submodules and builds/installs their outputs (MonoLisa fonts, SbarLua, sketchybar-app-font). Public submodules are cloned via HTTPS; private submodules (font-monolisa, monolisa-nerdfont-patch) require SSH and are silently skipped when SSH auth is unavailable. Run automatically by chezmoi (`run_onchange_`) whenever `.gitmodules` changes.

```sh
./scripts/git/install-submodules.sh
# or
mise run git:install-submodules
```

## `brew/install-packages.sh`

Installs all Homebrew packages declared in `~/.Brewfile` via `brew bundle`. Run automatically by chezmoi (`run_onchange_`) whenever `dot_Brewfile` changes.

```sh
./scripts/brew/install-packages.sh
# or
mise run brew:install-packages
```

## `luarocks/install-rocks.sh`

Installs LuaRocks dependencies into the user tree (`~/.luarocks`). Homebrew Bundle has no luarocks entry type, so rocks live here rather than the Brewfile. Run automatically by chezmoi (`run_onchange_`) whenever the script changes; see [ops/upgrade-hazards.md](ops/upgrade-hazards.md) for the Lua-version coupling.

```sh
./scripts/luarocks/install-rocks.sh
# or
mise run luarocks:install-rocks
```

## `tinted/apply-templates.sh`

Builds theme outputs (zsh script, Ghostty colorscheme, VS Code extension) from a Base24 scheme directory and installs them via tinted-builder. Run after modifying any palette in `Library/Themes/`.

```sh
./scripts/tinted/apply-templates.sh <theme-name>
# or
mise run tinted:apply-templates -- <theme-name>
```

## `themes/generate_base24_palette.py`

Generates Base24 dark and light palette YAML files using HCT color space algorithms. Run after modifying the palette generation logic in `scripts/themes/`.

```sh
uv run ./scripts/themes/generate_base24_palette.py
# or
mise run themes:generate-base24-palette
```

## `themes/handle-theme-change.sh`

Orchestrator for per-appearance theme state. Detects (or accepts) the current light/dark mode, then:

- Calls `borders/handle-theme-change.sh` to recolor [JankyBorders](https://github.com/FelixKratz/JankyBorders).
- Writes `~/.config/delta/mode.gitconfig` with `features = zebra-dark` (or `zebra-light`), which the main git config includes — driving [delta](https://github.com/dandavison/delta)'s `colorMoved` feature for shell `git diff` output.
- Re-applies Spotify's [Spicetify](https://spicetify.app) Catppuccin scheme (`mocha` in dark, `latte` in light), quitting and restoring Spotify around the patch — reopened only if it was running, playback resumed only if it was playing.

Normally invoked automatically by `dark-notify`, but can be run manually to force a refresh.

```sh
./scripts/themes/handle-theme-change.sh            # detect from system
./scripts/themes/handle-theme-change.sh dark|light
# or
mise run themes:handle-theme-change            # detect from system
mise run themes:handle-theme-change -- dark|light
```

## `borders/handle-theme-change.sh`

Applies the correct accent colors to `borders` for the current light/dark mode. Invoked by `bordersrc` at borders startup (with no args; self-detects) and by `themes/handle-theme-change.sh` on every appearance change (with the resolved mode passed in).

```sh
./scripts/borders/handle-theme-change.sh            # detect from system
./scripts/borders/handle-theme-change.sh dark|light
```

## `zsh/benchmark-startup.sh`

Benchmarks Zsh startup time using `hyperfine` (200 runs, 50 warmups). Useful when tuning the Zsh config.

```sh
./scripts/zsh/benchmark-startup.sh
# or
mise run zsh:benchmark-startup
```
