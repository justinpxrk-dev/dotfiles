# skhd Keyboard Shortcuts

## Focus Window

| Shortcut | Command |
| -------- | ------- |
| ⌥H | `yabai -m window --focus west` |
| ⌥J | `yabai -m window --focus south` |
| ⌥K | `yabai -m window --focus north` |
| ⌥L | `yabai -m window --focus east` |

## Move Window

| Shortcut | Command |
| -------- | ------- |
| ⇧⌥H | `yabai -m window --swap west` |
| ⇧⌥J | `yabai -m window --swap south` |
| ⇧⌥K | `yabai -m window --swap north` |
| ⇧⌥L | `yabai -m window --swap east` |

## Move Window to Space

| Shortcut | Command |
| -------- | ------- |
| ⇧⌥1–9 | `yabai -m window --space <n>` |

## Resize Window

| Shortcut | Command                                                         |
| -------- | --------------------------------------------------------------- |
| ⇧⌥←      | `yabai -m window --resize left:-20:0` (push left border out)    |
| ⇧⌥→      | `yabai -m window --resize right:20:0` (push right border out)   |
| ⇧⌥↑      | `yabai -m window --resize top:0:-20` (push top border out)      |
| ⇧⌥↓      | `yabai -m window --resize bottom:0:20` (push bottom border out) |

## Toggle

| Shortcut | Command |
| -------- | ------- |
| ⌥T | `yabai -m window --toggle float` |
| ⌥F | `yabai -m window --toggle zoom-fullscreen` |

## Layout

| Shortcut | Command |
| -------- | ------- |
| ⌥R | `yabai -m space --rotate 90` |
| ⇧⌥0 | `yabai -m space --balance` |

## Services

| Shortcut | Command |
| -------- | ------- |
| ⇧⌥Q | `yabai --restart-service` |
| ⇧⌥E | `skhd --restart-service` |
