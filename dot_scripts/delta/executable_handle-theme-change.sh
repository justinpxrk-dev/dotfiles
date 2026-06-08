#!/usr/bin/env bash

set -euo pipefail

# Mode (dark|light) is resolved once by themes/handle-theme-change.sh and passed
# in; this handler does not detect it itself.
MODE="${1:?expected dark|light}"

# Swap delta's theme feature to match appearance: Catppuccin Mocha for dark,
# Latte for light, from the catppuccin/delta submodule whose catppuccin.gitconfig
# the main git config includes. Each flavor carries its own colorMoved map-styles,
# so it recolors moved blocks too. git silently skips missing include paths, so
# the first run after chezmoi apply (before this hook has fired) is harmless.
# Self-resolve DELTA_CONFIG_HOME so LaunchAgent invocations (no zshenv) work.
: "${DELTA_CONFIG_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}/delta}"
DELTA_FEATURE=$([[ "$MODE" == "dark" ]] && echo "catppuccin-mocha" || echo "catppuccin-latte")
[[ -d "$DELTA_CONFIG_HOME" ]] || mkdir -p "$DELTA_CONFIG_HOME"
cat >"$DELTA_CONFIG_HOME/mode.gitconfig" <<EOF
[delta]
    features = $DELTA_FEATURE
EOF
