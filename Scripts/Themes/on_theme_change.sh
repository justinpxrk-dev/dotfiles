#!/usr/bin/env bash

# dark-notify passes "dark" or "light" as $1; fall back to defaults read
# when called directly at startup (e.g. from bordersrc)
if [[ -n "$1" ]]; then
	MODE="$1"
else
	RESULT=$(defaults read -g AppleInterfaceStyle 2>/dev/null)
	MODE=$([[ "$RESULT" == "Dark" ]] && echo "dark" || echo "light")
fi

if [[ "$MODE" == "dark" ]]; then
	borders active_color=0x997ead67 inactive_color=0x992c2c2c
else
	borders active_color=0x99ffffff inactive_color=0x99555555
fi
