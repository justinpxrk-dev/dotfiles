#!/usr/bin/env bash

set -euo pipefail

main() {
	local launch_agents_dir="$HOME/Library/LaunchAgents"
	local log_dir="$HOME/Library/Logs/me.justinpxrk"
	local uid_num
	uid_num="$(id -u)"

	[[ -d "$log_dir" ]] || mkdir -p "$log_dir"

	local prev_nullglob
	prev_nullglob=$(shopt -p nullglob) || true
	shopt -s nullglob
	local plists=("$launch_agents_dir"/me.justinpxrk.*.plist)
	eval "$prev_nullglob"

	if ((${#plists[@]} == 0)); then
		echo "==> No me.justinpxrk LaunchAgents found in $launch_agents_dir"
		return 0
	fi

	local failed=()
	local plist label
	for plist in "${plists[@]}"; do
		label="$(defaults read "$plist" Label 2>/dev/null)"
		echo "==> $label"
		if launchctl list "$label" &>/dev/null; then
			echo "  > Already registered, skipping"
			continue
		fi
		if ! launchctl bootstrap "gui/$uid_num" "$plist" 2>&1; then
			failed+=("$label")
		fi
	done

	if ((${#failed[@]} > 0)); then
		echo "==> The following agents failed to register:" >&2
		printf '  > %s\n' "${failed[@]}" >&2
		return 1
	fi

	echo "==> Done"
}

main "$@"
