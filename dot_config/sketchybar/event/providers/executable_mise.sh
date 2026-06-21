#!/usr/bin/env bash
#
# Print the number of outdated mise-managed tools to stdout (one integer, nothing else), for the
# sketchybar updates pill's mise segment (see plugins/updates.lua).
#
# Scoped to the dotfiles repo's toolchain via `-C`: this machine keeps no *global* mise tools
# (~/.config/mise/config.toml is empty), so the only meaningful "are my mise tools behind?" question
# is the repo-root mise.toml that drives the dotfiles dev environment (node, pnpm, ruff, stylua, …).
# `-C` makes the count independent of sketchybar's working directory. Re-point mise_dir to track a
# different project (see docs/ops/upgrade-hazards.md).
#
# `--json` emits an object keyed by tool name (`{}` when all up to date); the count is the number of
# keys (`jq length`). mise/jq paths are absolute because sketchybar's `exec` runs with a minimal
# PATH. Always emits a number: any missing tool or failure prints 0, so a transient error reads as
# "no updates" rather than breaking the pill's count parsing.
set -uo pipefail

mise_bin=/opt/homebrew/bin/mise
jq_bin=/opt/homebrew/bin/jq
mise_dir="$HOME/.local/share/chezmoi"

if [[ ! -x $mise_bin || ! -x $jq_bin || ! -d $mise_dir ]]; then
	printf '0\n'
	exit 0
fi

# Capture separately so a mise failure falls back to an empty object (count 0) rather than feeding
# jq garbage.
json=$("$mise_bin" outdated -C "$mise_dir" --json 2>/dev/null) || json='{}'
[[ -n $json ]] || json='{}'
printf '%s' "$json" | "$jq_bin" 'length' 2>/dev/null || printf '0\n'
