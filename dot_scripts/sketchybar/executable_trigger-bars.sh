#!/usr/bin/env bash

# Trigger a sketchybar event on BOTH sketchybar instances: the default top bar and the
# external bar (registered as git.felix.external). sketchybar selects the instance by
# argv[0]; yabai is not a sketchybar child, so the external instance is named explicitly
# via `exec -a external`. When the external display is undocked its daemon may be gone,
# so that trigger is best-effort — stderr is suppressed and it never fails the script.

event="$1"

/opt/homebrew/bin/sketchybar --trigger "$event"
(exec -a external /opt/homebrew/bin/sketchybar --trigger "$event") 2>/dev/null || true
