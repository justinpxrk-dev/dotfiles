# `skhd` Keyboard Shortcuts

Window and space bindings follow a modifier grammar (HJKL = left/down/up/right):

| Layer | Meaning                                                       |
| ----- | ------------------------------------------------------------- |
| ⌥     | focus window (HJKL)                                           |
| ⇧⌥    | resize window (HJKL)                                          |
| ⌃⌥    | move window — swap in place (HJKL), send to space (C, V, 1–9) |
| ⌘⌥    | _reserved for Ghostty splits — never bind in `skhdrc`_        |

⌘⌥ is intentionally unbound: skhd grabs hotkeys globally before any app sees them, so leaving that layer free is what lets Ghostty receive its [split chords](../ghostty/keyboard-shortcuts.md).

## Focus Window

| Shortcut | Command                         |
| -------- | ------------------------------- |
| ⌥H       | `yabai -m window --focus west`  |
| ⌥J       | `yabai -m window --focus south` |
| ⌥K       | `yabai -m window --focus north` |
| ⌥L       | `yabai -m window --focus east`  |

## Move Window (Swap in Place)

| Shortcut | Command                        |
| -------- | ------------------------------ |
| ⌃⌥H      | `yabai -m window --swap west`  |
| ⌃⌥J      | `yabai -m window --swap south` |
| ⌃⌥K      | `yabai -m window --swap north` |
| ⌃⌥L      | `yabai -m window --swap east`  |

## Move Window to Space

| Shortcut | Command                        |
| -------- | ------------------------------ |
| ⌃⌥C      | `yabai -m window --space prev` |
| ⌃⌥V      | `yabai -m window --space next` |
| ⌃⌥1–9    | `yabai -m window --space <n>`  |

## Resize Window

| Shortcut | Command                                                         |
| -------- | --------------------------------------------------------------- |
| ⇧⌥H      | `yabai -m window --resize left:-20:0` (push left border out)    |
| ⇧⌥J      | `yabai -m window --resize bottom:0:20` (push bottom border out) |
| ⇧⌥K      | `yabai -m window --resize top:0:-20` (push top border out)      |
| ⇧⌥L      | `yabai -m window --resize right:20:0` (push right border out)   |

## Toggle

| Shortcut | Command                                    |
| -------- | ------------------------------------------ |
| ⌥T       | `yabai -m window --toggle float`           |
| ⌥F       | `yabai -m window --toggle zoom-fullscreen` |

## Layout

| Shortcut | Command                      |
| -------- | ---------------------------- |
| ⌥R       | `yabai -m space --rotate 90` |
| ⇧⌥0      | `yabai -m space --balance`   |

## Terminal

| Shortcut | Command                                         |
| -------- | ----------------------------------------------- |
| ⌥↩       | `~/.scripts/ghostty/open-new-window.sh`         |
| ⇧⌥↩      | `~/.scripts/ghostty/open-new-window.sh --float` |

## Services

| Shortcut | Command                   |
| -------- | ------------------------- |
| ⇧⌥Q      | `yabai --restart-service` |
| ⇧⌥E      | `skhd --restart-service`  |
