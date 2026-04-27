#!/usr/bin/env bash

set -euo pipefail

LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
UID_NUM="$(id -u)"

failed=()

shopt -s nullglob
plists=("$LAUNCH_AGENTS_DIR"/com.justinpxrk.*.plist)

if ((${#plists[@]} == 0)); then
	echo "==> No com.justinpxrk LaunchAgents found in $LAUNCH_AGENTS_DIR"
	exit 0
fi

for plist in "${plists[@]}"; do
	label="$(defaults read "$plist" Label 2>/dev/null)"
	echo "==> $label"
	if launchctl list "$label" &>/dev/null; then
		echo "  > Already registered, skipping"
		continue
	fi
	if ! launchctl bootstrap "gui/$UID_NUM" "$plist" 2>&1; then
		failed+=("$label")
	fi
done

if ((${#failed[@]} > 0)); then
	echo "==> The following agents failed to register:" >&2
	printf '  > %s\n' "${failed[@]}" >&2
	exit 1
fi

echo "==> Done"
