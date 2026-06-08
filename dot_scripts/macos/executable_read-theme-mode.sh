#!/usr/bin/env bash
# Echo the current macOS appearance mode, "dark" or "light" — the single place
# that queries the system. Every other script receives the mode as an argument
# and passes it down, so this runs only for arg-less entry points: a manual
# run, the one-time chezmoi bootstrap, and bordersrc at borders startup.

set -euo pipefail

# AppleInterfaceStyle only exists in dark mode; defaults read exits 1 in light mode
RESULT=$(defaults read -g AppleInterfaceStyle 2>/dev/null) || RESULT="Light"
if [[ "$RESULT" == "Dark" ]]; then
	echo "dark"
else
	echo "light"
fi
