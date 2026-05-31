#!/usr/bin/env bash

set -euo pipefail

# Optional $1 is "dark" or "light". When unset, detect from system appearance
# so this script can be invoked standalone (e.g. from bordersrc at borders
# startup, where the mode hasn't been resolved yet).
if [[ -n "${1:-}" ]]; then
	MODE="$1"
else
	# AppleInterfaceStyle only exists in dark mode; defaults read exits 1 in light mode
	RESULT=$(defaults read -g AppleInterfaceStyle 2>/dev/null) || RESULT="Light"
	MODE=$([[ "$RESULT" == "Dark" ]] && echo "dark" || echo "light")
fi

if [[ "$MODE" == "dark" ]]; then
	borders active_color=0xff729f5b inactive_color=0xff2c2c2c
else
	borders active_color=0xffebebeb inactive_color=0xff555555
fi
