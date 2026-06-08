#!/usr/bin/env bash

set -euo pipefail

# Optional $1 is "dark" or "light"; when unset, read-theme-mode.sh detects from
# the system so this runs standalone — bordersrc invokes it at borders startup.
# The orchestrator passes the resolved mode, so a flip needs no extra query.
MODE="${1:-$("$(dirname "$0")/../macos/read-theme-mode.sh")}"

if [[ "$MODE" == "dark" ]]; then
	borders active_color=0xd6b4befe inactive_color=0xd61e1e2e
else
	borders active_color=0xd67287fd inactive_color=0xd6eff1f5
fi
