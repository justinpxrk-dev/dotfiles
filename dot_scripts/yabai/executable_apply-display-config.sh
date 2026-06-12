#!/usr/bin/env bash

# apply-display-config.sh — set per-display yabai bottom padding, keyed by each
# display's stable UUID. Padding in yabai is a per-space setting with no
# per-display selector, and both the space-to-display mapping and the display
# index reshuffle on dock/undock — so resolve each monitor by UUID (stable) and
# pad every space on it to clear that monitor's sketchybar:
#   - built-in "Color LCD" (main): bar mirrors the top menubar, so nothing sits
#     at the bottom — reclaim it (18, matching the other edges).
#   - external "LG 34GN850": bottom-of-screen bar, so reserve 66px.
# yabairc wires this to the display add/remove signals and runs it once on load.
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

# Pad each space for whichever bar lives on its display, resolved by UUID. A
# transient per-space failure (a space renumbered mid dock/undock) logs and the
# sweep continues, rather than aborting and leaving padding half-applied.
while read -r uuid space; do
	if [[ "$uuid" == "$BUILTIN_UUID" ]]; then
		padding=$MAIN_BOTTOM_PADDING
	else
		padding=$EXTERNAL_BOTTOM_PADDING
	fi
	yabai -m config --space "$space" bottom_padding "$padding" ||
		echo "apply-display-config: could not pad space $space" >&2
done <<<"$mapping"
