# Ghostty Keyboard Shortcuts

Split (pane) bindings live on the ⌘⌥ layer — adding ⌘ to [skhd's window layer](../skhd/keyboard-shortcuts.md) (⌥) means "one level inward", from yabai windows to Ghostty splits. These chords only reach Ghostty because skhd leaves ⌘⌥ unbound.

## Navigate Split

| Shortcut | Command            |
| -------- | ------------------ |
| ⌘⌥H      | `goto_split:left`  |
| ⌘⌥J      | `goto_split:down`  |
| ⌘⌥K      | `goto_split:up`    |
| ⌘⌥L      | `goto_split:right` |

## Resize Split

| Shortcut | Command                 |
| -------- | ----------------------- |
| ⇧⌘⌥H     | `resize_split:left,40`  |
| ⇧⌘⌥J     | `resize_split:down,40`  |
| ⇧⌘⌥K     | `resize_split:up,40`    |
| ⇧⌘⌥L     | `resize_split:right,40` |

## New Split

The divider mnemonic: the key looks like the line the split draws.

| Shortcut | Command           |
| -------- | ----------------- |
| ⌘⌥-      | `new_split:down`  |
| ⌘⌥\      | `new_split:right` |

## Manage Splits

⇧⌘⌥0 mirrors yabai's ⇧⌥0 balance, one layer in.

| Shortcut | Command             |
| -------- | ------------------- |
| ⌘⌥↩      | `toggle_split_zoom` |
| ⇧⌘⌥0     | `equalize_splits`   |

## Font Size

Ghostty defaults — not bound in `config.ghostty`, listed here because the split scheme was shaped around keeping them.

| Shortcut | Command              |
| -------- | -------------------- |
| ⌘=       | `increase_font_size` |
| ⌘-       | `decrease_font_size` |
| ⌘0       | `reset_font_size`    |
