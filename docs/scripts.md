# Scripts

Scripts are applied to `~/.scripts/` (source `dot_scripts/`, non-executable in the repo, `+x` on apply); run them directly by path. Bootstrap scripts (`install-packages.sh`, `install-submodules.sh`, `install-rocks.sh`, `claude-code/install.sh`, `reload-launch-agent.sh`) run automatically via chezmoi — manual invocation is only needed outside of `chezmoi apply`.

## PATH commands

Four user-facing scripts are also exposed as commands on `PATH` through thin `exec` wrappers in `~/.local/bin` (source `dot_local/bin/`), so they can be run by name from anywhere instead of by full path:

| Command                         | Wraps                                         |
| ------------------------------- | --------------------------------------------- |
| `handle-theme-change`           | `~/.scripts/themes/handle-theme-change.sh`    |
| `handle-theme-change-spicetify` | `~/.scripts/spicetify/handle-theme-change.sh` |
| `reload-launch-agent`           | `~/.scripts/macos/reload-launch-agent.sh`     |
| `benchmark-startup`             | `~/.scripts/zsh/benchmark-startup.sh`         |

Each wrapper `exec`s its target with `"$@"` forwarded. Using a wrapper rather than a symlink keeps the target running under its real path, so the theme orchestrator's `$0`-relative lookups still resolve its sibling scripts; `exec` then replaces the wrapper process so signals and exit status pass straight through.

## `macos/set-system-settings.sh`

Applies macOS defaults and system preferences. Reboot immediately after — opening System Settings can overwrite changes, and some settings only take effect on reboot.

```sh
~/.scripts/macos/set-system-settings.sh
```

> Some settings, such as those in Location Services, cannot be scripted. Manually configured settings are documented in [manual-setup.md](macos-system-settings/manual-setup.md).

## `macos/reload-launch-agent.sh`

Reloads a single `me.justinpxrk` LaunchAgent by label — `bootout` then `bootstrap`, so an edited plist replaces the running agent instead of leaving the stale one in place. Each agent has its own `run_onchange_after_reload-launch-agent-<name>.sh` chezmoiscript keyed on its plist, so chezmoi reloads only the agent whose plist changed (and bootstraps it on first install).

```sh
~/.scripts/macos/reload-launch-agent.sh me.justinpxrk.dark-notify
```

## `git/install-submodules.sh`

Initialises all git submodules and builds/installs their outputs (MonoLisa fonts, SbarLua, sketchybar-app-font). Public submodules are cloned via HTTPS; private submodules (font-monolisa, monolisa-nerdfont-patch) require SSH and are silently skipped when SSH auth is unavailable. Run automatically by chezmoi (`run_onchange_`) whenever `.gitmodules` changes.

```sh
~/.scripts/git/install-submodules.sh
```

## `brew/install-packages.sh`

Installs all Homebrew packages declared in `~/.Brewfile` via `brew bundle`. Run automatically by chezmoi (`run_onchange_`) whenever `dot_Brewfile` changes. In CI, `mas` (Mac App Store) apps are skipped via `HOMEBREW_BUNDLE_MAS_SKIP` because the runner has no App Store sign-in; the deploy workflow validates their IDs with `mas info` instead.

```sh
~/.scripts/brew/install-packages.sh
```

## `claude-code/install.sh`

Installs [Claude Code](https://code.claude.com/docs/en/setup) via its native installer (`curl -fsSL https://claude.ai/install.sh | bash`), which lands the binary at `~/.local/bin/claude` on the `latest` channel. The native installer pulls releases straight from upstream, so new versions are available as soon as they ship rather than waiting on Homebrew's `claude-code` cask to catch up — the switch was prompted by needing `claude-code` 2.170 for Fable 5 ahead of its Homebrew release. Installs only when `~/.local/bin/claude` is absent, so re-applies are no-ops; thereafter Claude Code self-updates. Run automatically by chezmoi (`run_onchange_`) whenever the script changes.

```sh
~/.scripts/claude-code/install.sh
```

## `luarocks/install-rocks.sh`

Installs LuaRocks dependencies into the user tree (`~/.luarocks`). Homebrew Bundle has no luarocks entry type, so rocks live here rather than the Brewfile. Run automatically by chezmoi (`run_onchange_`) whenever the script changes; see [ops/upgrade-hazards.md](ops/upgrade-hazards.md) for the Lua-version coupling.

```sh
~/.scripts/luarocks/install-rocks.sh
```

## `tinted/apply-templates.sh`

Builds the zsh theme output (shell profile helper and theme-switch scripts) from a Base24 scheme directory and installs it via tinted-builder. Run after modifying any palette in `Library/Themes/`.

```sh
~/.scripts/tinted/apply-templates.sh <theme-name>
```

## `themes/generate_base24_palette.py`

Generates Base24 dark and light palette YAML files using HCT color space algorithms. Run after modifying the palette generation logic in `dot_scripts/themes/`.

```sh
uv run ~/.scripts/themes/generate_base24_palette.py
```

## `themes/handle-theme-change.sh`

Orchestrator for per-appearance theme state. Resolves the mode — `$1` from dark-notify, else via `read-theme-mode.sh` — then fans out to each tool's sibling handler with it:

- `borders/handle-theme-change.sh` — recolors [JankyBorders](https://github.com/FelixKratz/JankyBorders).
- `delta/handle-theme-change.sh` — writes the delta Catppuccin theme feature for `git diff` output.
- `spicetify/handle-theme-change.sh` — re-applies Spotify's Catppuccin scheme.

Invoked automatically by `dark-notify` on every appearance change, once at install by `.chezmoiscripts/run_once_after_themes-handle-theme-change.sh`, or manually to force a refresh.

borders is normally always running — the Brewfile starts its service (`restart_service: :changed`) and launchd keeps it alive — so the orchestrator pushes the recolor straight to it. The `pgrep` guard only matters if that service has been stopped: `borders <props>` with no running instance starts borders in the foreground and never returns, which would wedge the caller (e.g. the dark-notify agent). When borders is down the orchestrator skips it, and borders re-applies the correct colors from `bordersrc` when its service restarts.

```sh
~/.scripts/themes/handle-theme-change.sh            # detect from system
~/.scripts/themes/handle-theme-change.sh dark|light
```

## `macos/read-theme-mode.sh`

Echoes the current macOS appearance mode (`dark`/`light`) — the single place that queries the system. Callers resolve the mode as `${1:-$(read-theme-mode.sh)}`, so it runs only when no mode was passed in: a manual run, the one-time bootstrap, `bordersrc` at borders startup, or a standalone `spicetify` re-sync. On a dark-notify flip the mode flows down from the orchestrator and nothing re-queries.

```sh
~/.scripts/macos/read-theme-mode.sh
```

## `borders/handle-theme-change.sh`

Applies the accent colors for the light/dark mode. Takes the mode as `$1` when the orchestrator passes it on a flip, or resolves it via `read-theme-mode.sh` when invoked without one — `bordersrc` runs it at borders startup.

```sh
~/.scripts/borders/handle-theme-change.sh            # detect from system
~/.scripts/borders/handle-theme-change.sh dark|light
```

## `delta/handle-theme-change.sh`

Writes `~/.config/delta/mode.gitconfig` with `features = catppuccin-mocha` (or `catppuccin-latte`) for the passed-in mode, which the main git config includes — selecting the [catppuccin/delta](https://github.com/catppuccin/delta) theme (each flavor carries its own `colorMoved` map-styles) for shell `git diff` output. Driven by `themes/handle-theme-change.sh`, which resolves the mode and passes it in.

```sh
~/.scripts/delta/handle-theme-change.sh dark|light
```

## `spicetify/handle-theme-change.sh`

Re-applies Spotify's [Spicetify](https://spicetify.app) Catppuccin scheme (`mocha` in dark, `latte` in light) for the current light/dark mode, quitting and restoring Spotify around the patch — reopened only if it was running, playback resumed only if it was playing. Invoked by `themes/handle-theme-change.sh` on every appearance change (with the resolved mode passed in), or standalone to re-sync (resolving the mode via `read-theme-mode.sh` when no arg is given).

```sh
~/.scripts/spicetify/handle-theme-change.sh            # detect from system
~/.scripts/spicetify/handle-theme-change.sh dark|light
```

## `zsh/benchmark-startup.sh`

Benchmarks Zsh startup time using `hyperfine` (200 runs, 50 warmups). Useful when tuning the Zsh config.

```sh
~/.scripts/zsh/benchmark-startup.sh
```

## `ghostty/open-new-window.sh`

Opens a new Ghostty window — tiled by default, floating centered with `--float`. Synthesizes `cmd - n` only when Ghostty already has a window, since launching it (or reopening it window-less) creates an initial window by itself and the extra keystroke would open a second one. The float variant registers a one-shot yabai rule that applies to the next Ghostty window and removes itself. Bound to `alt - return` / `shift + alt - return` in skhd.

```sh
~/.scripts/ghostty/open-new-window.sh [--float]
```

## `yabai/apply-display-config.sh`

Sets each display's yabai top and bottom padding to clear whatever sketchybar lives on it, keyed by the display's stable UUID — yabai padding is per-space with no per-display selector, and both the space→display mapping and display indices reshuffle on dock/undock. Each bar edge is tuned so windows sit a uniform 14px from that bar's pills — the same gap `yabairc` gives the bar-less edges: 8px top on the built-in lands 14px below its top-bar pills, 47px bottom on the external lands 14px above its bottom-bar pills. `yabairc` runs it once on load and on `display_added`/`display_removed`, so the layout re-mirrors whenever a monitor is plugged or unplugged.

```sh
~/.scripts/yabai/apply-display-config.sh
```

## `sketchybar/trigger-bars.sh`

Fans a sketchybar `--trigger` out to **both** instances — the default top bar and the `external` bar (`git.felix.external`). yabai's space/window/app signals call it so each display's space indicators refresh together: a bare `sketchybar --trigger` only reaches the default instance, so the external one is selected explicitly via `exec -a external`. The external trigger is best-effort (stderr suppressed, never fails), so it's a harmless no-op when the external display is undocked.

```sh
~/.scripts/sketchybar/trigger-bars.sh <event>
```
