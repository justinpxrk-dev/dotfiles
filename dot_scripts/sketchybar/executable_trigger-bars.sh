#!/usr/bin/env bash

# Fan an event out to both bars. Each daemon may be absent during startup or undocking.
# Arguments: event name. Returns success after attempting both deliveries.

set -u

if [[ $# -ne 1 || -z "$1" ]]; then
	echo "usage: trigger-bars.sh <event>" >&2
	exit 2
fi

event="$1"

/opt/homebrew/bin/sketchybar --trigger "$event" 2>/dev/null || true
(exec -a external /opt/homebrew/bin/sketchybar --trigger "$event") 2>/dev/null || true
