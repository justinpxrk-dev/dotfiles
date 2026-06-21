# TODO.md

## `now_playing`

- [ ] Figure out how to kill dispatcher when sketchybar exits/reloads.
  - No problem when using `brew services restart`
  - Dispatchers continue to run when sketchybar is run with `hotload=true`, which interferes with development (multiple conflicting events from different running dispatcher versions)
- [ ] Current 24x24 images in `assets/apple-music` are 30% opacity. Create 100% opacity version for use when artwork data is available.
- [ ] When a track is changed but there is no artwork data, the now playing artwork does not get changed. Then, if you pause/unpause, you'll see the previous track's artwork being displayed when there should no be artwork displayed.
  - FIX: Have the media event dispatcher also emit whether artworkMimeType != 'null' when `now_playing_track_change`is triggered. This way, the handler can set the artwork data to the default logo if no artwork data is available.

## Refactors

- [ ] `constants/option.lua` — Write better typings for this file.
- [ ] Collapse `constants/item.lua` and `constants/option.lua` into one file.
- [ ] Improve performance by researching how sbarLua execs `sbar` calls and batch them if needed.
- [ ] Move dispatcher's caching directory to `$TMPDIR`

## System Items

- [ ] CPU/GPU Performance, RAM usage, disk read/write, network down/up
- [x] Outdated homebrew packages — the `updates` pill (`plugins/updates.lua`), a modular provider registry that also covers **mise** outdated tools (scoped to the dotfiles toolchain). Add a source = one registry entry + `event/providers/<name>.sh`.
- [ ] ~~Outdated app store apps~~ — deferred: no `mas`-managed apps (`dot_Brewfile` has none), and GUI apps are casks already counted by `brew outdated`. Revisit if `mas` apps are added.
