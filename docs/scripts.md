# Scripts

Scripts live under `Scripts/` and are run from the repo root. All scripts are also available as mise tasks — run `mise tasks` for the full list, or `mise run <task>` to invoke one. Bootstrap scripts (`install_packages.sh`, `install_submodules.sh`, `install_rocks.sh`, `register_launch_agents.sh`) run automatically via chezmoi — manual invocation is only needed outside of `chezmoi apply`.

## `set_system_settings.sh`

Applies macOS defaults and system preferences. Reboot immediately after — opening System Settings can overwrite changes, and some settings only take effect on reboot.

```sh
./Scripts/macos/set_system_settings.sh
# or
mise run macos:settings
```

> Some settings, such as those in Location Services, cannot be scripted. Manually configured settings are documented in [macos-manual-settings.md](macos/macos-manual-settings.md).

## `register_launch_agents.sh`

Bootstraps all `me.justinpxrk.*` plists in `~/Library/LaunchAgents` into the current login session. Run automatically by chezmoi (`run_once_after_`) on first apply.

```sh
./Scripts/macos/register_launch_agents.sh
# or
mise run macos:launch-agents
```

## `install_submodules.sh`

Initialises all git submodules and builds/installs their outputs (MonoLisa fonts, SbarLua, sketchybar-app-font). Public submodules are cloned via HTTPS; private submodules (font-monolisa, monolisa-nerdfont-patch) require SSH and are silently skipped when SSH auth is unavailable. Run automatically by chezmoi (`run_onchange_`) whenever `.gitmodules` changes.

```sh
./Scripts/git/install_submodules.sh
# or
mise run git:submodules
```

## `install_packages.sh`

Installs all Homebrew packages declared in `~/.Brewfile` via `brew bundle`. Run automatically by chezmoi (`run_onchange_`) whenever `dot_Brewfile` changes.

```sh
./Scripts/brew/install_packages.sh
# or
mise run brew:install
```

## `install_rocks.sh`

Installs LuaRocks dependencies into the user tree (`~/.luarocks`). Homebrew Bundle has no luarocks entry type, so rocks live here rather than the Brewfile. Run automatically by chezmoi (`run_onchange_`) whenever the script changes; see [ops/upgrade-hazards.md](ops/upgrade-hazards.md) for the Lua-version coupling.

```sh
./Scripts/luarocks/install_rocks.sh
# or
mise run luarocks:install
```

## `build_themes.sh`

Builds theme outputs (zsh script, Ghostty colorscheme, VS Code extension) from a Base24 scheme directory and installs them. Run after modifying any palette in `Themes/`.

```sh
./Scripts/Themes/build_themes.sh <theme-name>
# or
mise run themes:build -- <theme-name>
```

## `generate_base24_palette.py`

Generates Base24 dark and light palette YAML files using HCT color space algorithms. Run after modifying the palette generation logic in `Scripts/Themes/`.

```sh
uv run ./Scripts/Themes/generate_base24_palette.py
# or
mise run themes:generate-palette
```

## `handle_theme_change.sh`

Orchestrator for per-appearance theme state. Detects (or accepts) the current light/dark mode, then:

- Calls `borders_apply_mode.sh` to recolor [JankyBorders](https://github.com/FelixKratz/JankyBorders).
- Writes `~/.config/delta/mode.gitconfig` with `features = zebra-dark` (or `zebra-light`), which the main git config includes — driving [delta](https://github.com/dandavison/delta)'s `colorMoved` feature for shell `git diff` output.
- Re-applies Spotify's [Spicetify](https://spicetify.app) Catppuccin scheme (`mocha` in dark, `latte` in light), quitting and restoring Spotify around the patch — reopened only if it was running, playback resumed only if it was playing.

Normally invoked automatically by `dark-notify`, but can be run manually to force a refresh.

```sh
./Scripts/Themes/handle_theme_change.sh            # detect from system
./Scripts/Themes/handle_theme_change.sh dark|light
# or
mise run themes:change-mode                    # detect from system
mise run themes:change-mode -- dark|light
```

## `borders_apply_mode.sh`

Applies the correct accent colors to `borders` for the current light/dark mode. Invoked by `bordersrc` at borders startup (with no args; self-detects) and by `handle_theme_change.sh` on every appearance change (with the resolved mode passed in).

```sh
./Scripts/Themes/borders_apply_mode.sh            # detect from system
./Scripts/Themes/borders_apply_mode.sh dark|light
```

## `benchmark_startup.sh`

Benchmarks Zsh startup time using `hyperfine` (200 runs, 10 warmups). Useful when tuning the Zsh config.

```sh
./Scripts/zsh/benchmark_startup.sh
# or
mise run zsh:benchmark
```
