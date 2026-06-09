#!/usr/bin/env bash
# Open a new Ghostty window — tiled by default, floating centered with
# --float. Invoked by skhd (alt - return / shift + alt - return); safe to run
# manually.

set -euo pipefail

# A one-shot rule floats only the next Ghostty window to spawn, then removes
# itself — no timed cleanup, and it still applies when a cold launch takes
# longer than a fixed timeout would allow. Re-adding the label replaces any
# leftover rule from a press where no window ever spawned.
if [[ "${1:-}" == "--float" ]]; then
	yabai -m rule --add --one-shot label=ghostty-float-next app="^Ghostty$" manage=off grid=4:4:1:1:2:2
fi

# Synthesize cmd-n only when Ghostty already has a window: launching it (or
# reopening it window-less) creates an initial window by itself, so an
# unconditional cmd-n would open a second window — or land in the previously
# focused app if Ghostty hasn't taken focus yet. Query before `open`: after it
# returns, the initial window may already be registered, which would
# mis-detect a cold launch as "has windows".
if yabai -m query --windows | jq -e 'any(.app == "Ghostty")' >/dev/null; then
	open -b com.mitchellh.ghostty
	skhd -k "cmd - n"
else
	open -b com.mitchellh.ghostty
fi
