#!/usr/bin/env bash

set -euo pipefail

# Reload a single LaunchAgent by label: bootout (ignored when not loaded) then
# bootstrap, so an edited plist replaces the running agent instead of leaving
# the stale definition in place. Invoked per-agent by the run_onchange_ scripts
# in .chezmoiscripts/ (each keyed on one plist), and runnable manually.
main() {
	local label="${1:?label required, e.g. me.justinpxrk.dark-notify}"
	local plist="$HOME/Library/LaunchAgents/$label.plist"
	local uid_num
	uid_num="$(id -u)"

	if [[ ! -f "$plist" ]]; then
		echo "==> $label: $plist not found, skipping" >&2
		return 0
	fi

	# launchd does not create log directories, and a missing StandardErrorPath or
	# StandardOutPath parent makes the agent fail to start.
	local key path
	for key in StandardErrorPath StandardOutPath; do
		path="$(defaults read "$plist" "$key" 2>/dev/null)" || continue
		if [[ -n "$path" ]]; then
			mkdir -p "$(dirname "$path")"
		fi
	done

	echo "==> Reloading $label"
	launchctl bootout "gui/$uid_num" "$plist" 2>/dev/null || true
	# bootout is asynchronous — wait for the label to drop so the bootstrap below
	# doesn't race the teardown and fail with an I/O error.
	local i
	for ((i = 0; i < 50; i++)); do
		launchctl print "gui/$uid_num/$label" &>/dev/null || break
		sleep 0.1
	done
	launchctl bootstrap "gui/$uid_num" "$plist"
}

main "$@"
