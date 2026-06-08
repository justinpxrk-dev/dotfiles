#!/usr/bin/env bash
# Seed per-appearance theme state once, right after the first `chezmoi apply`,
# so delta/spicetify/borders match the current light/dark mode without waiting
# for the next dark-notify trigger.
#
# `once_` (not `onchange_`) keeps this a one-shot: it runs a single time and is
# not re-triggered when handle-theme-change.sh changes. `after_` plus the
# alphabetical name (`themes-...` sorts after `git-...` and the file-phase
# `brew-...`) guarantees the tools, configs, and the spicetify theme submodule
# are all in place before it fires.

set -euo pipefail

"$HOME/.scripts/themes/handle-theme-change.sh"
