#!/usr/bin/env bash

# apply-display-config.sh — set per-display yabai bottom padding, keyed by each
# display's stable UUID. Padding in yabai is a per-space setting with no
# per-display selector, and both the space-to-display mapping and the display
# index reshuffle on dock/undock — so resolve each monitor by UUID (stable) and
# pad every space on it to clear that monitor's sketchybar:
#   - built-in "Color LCD" (main): menubar at the top, so reclaim the bottom
#     (18, matching the other edges).
#   - external "LG 34GN850": spaces panel at the bottom, so reserve 66px.
# yabairc refreshes padding when spaces or displays change, and once on load.
#
# BUILTIN_UUID is hardware-specific: replacing the built-in panel means updating
# it (find the new value via `yabai -m query --displays | jq -r '.[].uuid'`).

set -euo pipefail

# yabai/jq live in Homebrew's bin, which a yabai signal's exec env may lack.
# Prepend it only when absent, and skip the separator when PATH is empty so we
# never leave a trailing colon (which would silently put the cwd on PATH).
if [[ ":${PATH:-}:" != *":/opt/homebrew/bin:"* ]]; then
	export PATH="/opt/homebrew/bin${PATH:+:$PATH}"
fi

readonly BUILTIN_UUID="37D8832A-2D66-02CA-B9F7-8F30A301B230"
readonly MAIN_BOTTOM_PADDING=18     # built-in: top bar, nothing to clear below
readonly EXTERNAL_BOTTOM_PADDING=66 # external: bottom bar to clear

# Snapshot the per-display space list up front. A failed query (e.g. a
# display_added signal firing before the window server settles) is invisible to
# `set -e` through a process substitution, which would leave the script a silent
# no-op exactly when a display just changed.
if ! mapping=$(yabai -m query --displays | jq -r '.[] | .uuid as $uuid | .spaces[] | "\($uuid) \(.)"'); then
	echo "apply-display-config: yabai query failed" >&2
	exit 1
fi
if [[ -z "$mapping" ]]; then
	echo "apply-display-config: no spaces returned, nothing to pad" >&2
	exit 1
fi

# A space can be renumbered while displays change. Attempt the whole snapshot
# and report partial failure after the sweep so other spaces still get padding.
padding_status=0
while read -r uuid space; do
	if [[ "$uuid" == "$BUILTIN_UUID" ]]; then
		padding=$MAIN_BOTTOM_PADDING
	else
		padding=$EXTERNAL_BOTTOM_PADDING
	fi
	if ! yabai -m config --space "$space" bottom_padding "$padding"; then
		echo "apply-display-config: could not pad space $space" >&2
		padding_status=1
	fi
done <<<"$mapping"

exit "$padding_status"
