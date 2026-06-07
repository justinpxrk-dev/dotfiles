#!/usr/bin/env bash

set -euo pipefail

# Mode (dark|light) is resolved once by themes/handle-theme-change.sh and passed
# in; this handler does not detect it itself.
MODE="${1:?expected dark|light}"

# Swap delta's color-moved feature to match appearance. The main git config
# includes this file; git silently skips missing include paths, so the first run
# after chezmoi apply (before this hook has fired) is harmless. Self-resolve
# DELTA_CONFIG_HOME so LaunchAgent invocations (no zshenv) work.
: "${DELTA_CONFIG_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}/delta}"
DELTA_FEATURE=$([[ "$MODE" == "dark" ]] && echo "zebra-dark" || echo "zebra-light")
[[ -d "$DELTA_CONFIG_HOME" ]] || mkdir -p "$DELTA_CONFIG_HOME"
cat >"$DELTA_CONFIG_HOME/mode.gitconfig" <<EOF
[delta]
    features = $DELTA_FEATURE
EOF
