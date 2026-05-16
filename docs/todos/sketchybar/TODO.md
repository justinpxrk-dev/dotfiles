# TODO.md

> There are `TODO` comments distributed throughout that are not documented here.

## `now_playing`

- Figure out how to kill dispatcher when sketchybar exits/reloads.
  - No problem when using `brew services restart`
  - Dispatchers continue to run when sketchybar is run with `hotload=true`, which interferes with development (multiple conflicting events from different running dispatcher versions)
- When a track is changed but there is no artwork data, the now playing artwork does not get changed. Then, if you pause/unpause, you'll see the previous track's artwork being displayed when there should no be artwork displayed.
  - FIX: Have the media event dispatcher also emit whether artworkMimeType != 'null' when `now_playing_track_change`is triggered. This way, the handler can set the artwork data to the default logo if no artwork data is available.


## Refactors

- Collapse `constants/item.lua` and `constants/option.lua` into one file.
- Improve performance by researching how sbarLua execs `sbar` calls and batch them if needed.
- Move dispatcher's caching directory to `$TMPDIR`

## System Items

- CPU/GPU Performance, RAM usage, disk read/write, network down/up
- Outdated homebrew packages
- Outdated app store apps
