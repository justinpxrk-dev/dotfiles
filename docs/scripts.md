# Scripts

All scripts live under `Scripts/` and are run from the repo root.

### `set_system_settings.sh`

Applies macOS defaults and system preferences. Reboot immediately after — opening System Settings can overwrite changes, and some settings only take effect on reboot.

```sh
./Scripts/macos/set_system_settings.sh
```

> Some settings, such as those in Location Services, cannot be scripted. Manually configured settings are documented in [macos-manual-settings.md](macos/macos-manual-settings.md).

### `register_launch_agents.sh`

Bootstraps all `com.justinpxrk.*` plists in `~/Library/LaunchAgents` into the current login session. Run after `chezmoi apply` whenever LaunchAgent plists are added or changed.

```sh
./Scripts/macos/register_launch_agents.sh
```

### `install_submodules.sh`

Initialises all git submodules and builds/installs their outputs (MonoLisa fonts, SbarLua, sketchybar-app-font). Run once after a fresh clone, and again whenever submodules are updated.

```sh
./Scripts/git/install_submodules.sh
```

### `install_tools.sh`

Installs Cargo-managed CLI tools (`tinted-builder-rust`). Run once after a fresh clone or when tool versions need updating.

```sh
./Scripts/cargo/install_tools.sh
```

### `build_themes.sh`

Builds theme outputs (Ghostty colorscheme, VS Code extension) from a Base24 scheme directory and installs them. Run after modifying any palette in `Themes/`.

```sh
./Scripts/Themes/build_themes.sh <theme-name>
```

### `on_theme_change.sh`

Applies the correct accent colors to `borders` for the current light/dark mode. Normally invoked automatically by `dark-notify`, but can be run manually to force a refresh.

```sh
./Scripts/Themes/on_theme_change.sh [dark|light]
```

### `benchmark_startup.sh`

Benchmarks Zsh startup time using `hyperfine` (200 runs, 10 warmups). Useful when tuning the Zsh config.

```sh
./Scripts/zsh/benchmark_startup.sh
```
