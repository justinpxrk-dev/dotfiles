#!/usr/bin/env bash

set -euo pipefail

script_dir=$(dirname "$0")

# dark-notify hands us the mode as $1; query the system via read-theme-mode.sh
# only when invoked without one — a manual run, or the one-time chezmoi
# bootstrap. Fan it out to each tool's sibling handler under scripts/<tool>/.
MODE="${1:-$("$script_dir/../macos/read-theme-mode.sh")}"

# borders is normally always up (the Brewfile starts its service and launchd
# keeps it alive), so recolor it directly. The guard only matters if that
# service has been stopped: `borders <props>` with no running instance starts
# borders in the foreground and never returns, wedging whatever invoked us (e.g.
# the dark-notify agent). When it's down we skip — borders re-reads the right
# colors from bordersrc when its service restarts.
if pgrep -x borders >/dev/null 2>&1; then
	"$script_dir/../borders/handle-theme-change.sh" "$MODE"
fi
"$script_dir/../delta/handle-theme-change.sh" "$MODE"
"$script_dir/../spicetify/handle-theme-change.sh" "$MODE"
