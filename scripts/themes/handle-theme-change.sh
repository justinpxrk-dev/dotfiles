#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC1072,SC1073

set -euo pipefail

# dark-notify passes "dark" or "light" as $1; fall back to defaults read when
# invoked manually (e.g. via `mise run themes:handle-theme-change`).
if [[ -n "${1:-}" ]]; then
	MODE="$1"
else
	# AppleInterfaceStyle only exists in dark mode; defaults read exits 1 in
	# light mode
	RESULT=$(defaults read -g AppleInterfaceStyle 2>/dev/null) || RESULT="Light"
	MODE=$([[ "$RESULT" == "Dark" ]] && echo "dark" || echo "light")
fi

# Recolor borders for the new mode (sibling script under scripts/borders/).
"$(dirname "$0")/../borders/handle-theme-change.sh" "$MODE"

# Swap delta's color-moved feature to match appearance. The main git config
# includes this file; git silently skips missing include paths, so the first run
# after chezmoi apply (before this hook has fired) is harmless. Self-resolve
# DELTA_CONFIG_HOME so LaunchAgent invocations (no zshenv) work.
: "${DELTA_CONFIG_HOME:=${XDG_CONFIG_HOME:-$HOME/.config}/delta}"
DELTA_FEATURE=$([[ "$MODE" == "dark" ]] &&
	echo "zebra-dark" ||
	echo "zebra-light")
[[ -d "$DELTA_CONFIG_HOME" ]] || mkdir -p "$DELTA_CONFIG_HOME"
cat >"$DELTA_CONFIG_HOME/mode.gitconfig" <<EOF
[delta]
    features = $DELTA_FEATURE
EOF

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
