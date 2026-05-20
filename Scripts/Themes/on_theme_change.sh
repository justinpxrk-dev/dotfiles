#!/usr/bin/env bash

set -euo pipefail

# dark-notify passes "dark" or "light" as $1; fall back to defaults read
# when invoked manually (e.g. via `mise run themes:change-mode`).
if [[ -n "${1:-}" ]]; then
	MODE="$1"
else
	# AppleInterfaceStyle only exists in dark mode; defaults read exits 1 in light mode
	RESULT=$(defaults read -g AppleInterfaceStyle 2>/dev/null) || RESULT="Light"
	MODE=$([[ "$RESULT" == "Dark" ]] && echo "dark" || echo "light")
fi

"$(dirname "$0")/borders_apply_mode.sh" "$MODE"

# Swap delta's color-moved feature to match appearance. The main git config
# includes this file; git silently skips missing include paths, so the first
# run after chezmoi apply (before this hook has fired) is harmless.
# Self-resolve DELTA_CONFIG_HOME so LaunchAgent invocations (no zshenv) work.
: "${DELTA_CONFIG_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}/delta}"
DELTA_FEATURE=$([[ "$MODE" == "dark" ]] && echo "zebra-dark" || echo "zebra-light")
[[ -d "$DELTA_CONFIG_HOME" ]] || mkdir -p "$DELTA_CONFIG_HOME"
cat >"$DELTA_CONFIG_HOME/mode.gitconfig" <<EOF
[delta]
    features = $DELTA_FEATURE
EOF
