#!/usr/bin/env bash
#
# Print the number of outdated Homebrew packages to stdout (one integer, nothing else), for the
# sketchybar updates pill's brew segment (see plugins/updates.lua).
#
# brew is exec'd through a tiny perl shim that resets SIGCHLD to its default disposition first, and
# this is ESSENTIAL: sketchybar runs item scripts with SIGCHLD *ignored* (SIG_IGN), and that
# disposition is inherited across fork/exec. Under SIG_IGN a process cannot reap its children, so
# Ruby (brew) can't collect the exit status of anything it shells out to — every `getconf`/`git`/…
# comes back with a nil status and brew aborts ("undefined method 'exitstatus'/'success?' for nil").
# Resetting SIGCHLD to SIG_DFL (which persists across the `exec` that follows) lets brew reap its
# children normally. mise needs no such shim — it is a single static binary that doesn't depend on
# the inherited SIGCHLD disposition. See docs/ops/upgrade-hazards.md.
#
# HOMEBREW_NO_AUTO_UPDATE keeps this a read: no `brew update` (tap git pull) runs; brew still
# refreshes its formulae API on its own cadence. Only `brew outdated` is ever run. `--quiet` prints
# one package name per line (outdated formulae plus non-auto-updating casks); the count is the line
# count. Absolute paths because sketchybar's `exec` runs with a minimal PATH.
#
# Always emits a number: any failure yields 0 (grep -c on empty input), so a transient error reads
# as "no updates" rather than breaking the pill's count parsing.
set -uo pipefail
export HOMEBREW_NO_AUTO_UPDATE=1

# Reset SIGCHLD (see above), then exec brew. stderr is dropped; `grep -c '^'` counts every line and
# prints 0 (exiting 1) on empty input, so `|| true` keeps that 0 without tripping `pipefail`.
/usr/bin/perl -e '$SIG{CHLD} = "DEFAULT"; exec @ARGV' \
	/opt/homebrew/bin/brew outdated --quiet 2>/dev/null | grep -c '^' || true
