#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC1072,SC1073

set -euo pipefail

# Optional $1 is "dark" or "light"; when unset, read-theme-mode.sh detects from
# the system so this handler works standalone (e.g. a manual run to
# re-sync). The orchestrator passes the resolved mode, so a flip needs no extra
# query.
MODE="${1:-$("$(dirname "$0")/../macos/read-theme-mode.sh")}"

# Sync Spicetify's Catppuccin theme to the appearance (dark -> Mocha, light -> Latte).
# Spotify must be closed to patch cleanly, so quit it first and then restore its
# prior state: reopen only if it was running, resume only if it was playing.
() {
	local color_scheme was_running="" was_playing="" state
	color_scheme=$([[ "$MODE" == "dark" ]] && echo "mocha" || echo "latte")

	if pgrep -x Spotify >/dev/null 2>&1; then
		was_running=1
		if [[ "$(osascript -e 'tell application "Spotify" to player state' 2>/dev/null)" == "playing" ]]; then
			was_playing=1
		fi
		osascript -e 'tell application "Spotify" to quit' 2>/dev/null || true
		# Wait for it to fully exit so the patch isn't fighting a live client.
		for _ in {1..20}; do
			if ! pgrep -x Spotify >/dev/null 2>&1; then break; fi
			sleep 0.25
		done
	fi

	# -n stops spicetify relaunching Spotify (we own the reopen below, so a closed
	# client stays closed); || true keeps a patch error from skipping that reopen.
	spicetify config current_theme catppuccin color_scheme "$color_scheme" \
		inject_css 1 inject_theme_js 1 replace_colors 1 overwrite_assets 1 || true
	spicetify -n apply || true

	if [[ -n "$was_running" ]]; then
		open -g -a Spotify
		if [[ -n "$was_playing" ]]; then
			# Wait for the relaunched client to accept AppleScript before resuming.
			for _ in {1..20}; do
				state=$(osascript -e 'tell application "Spotify" to player state' 2>/dev/null) || state=""
				if [[ -n "$state" ]]; then break; fi
				sleep 0.5
			done
			osascript -e 'tell application "Spotify" to play' 2>/dev/null || true
		fi
	fi
}
