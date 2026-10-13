# Sketchybar architecture

Two independent sketchybar instances run at once, one per display:

| Instance               | Profile        | Display           | Bar                   | LaunchAgent                         |
| ---------------------- | -------------- | ----------------- | --------------------- | ----------------------------------- |
| `sketchybar` (default) | `menubar`      | built-in (`main`) | top, full-width       | `me.justinpxrk.sketchybar`          |
| `sketchybar-external`  | `spaces-panel` | external (LG)     | bottom, rounded panel | `me.justinpxrk.sketchybar-external` |

A single instance has one global `bar` config (position, height, …) applied to every display it draws on, so a top bar on one screen and a bottom bar on another is impossible within one instance — hence two.

## How an instance is named and addressed

sketchybar derives its identity from **`basename(argv[0])`** and registers a mach bootstrap service `git.felix.<argv[0]>` (default `git.felix.sketchybar`); the CLI and SbarLua reach a bar by looking that name up. It does **not** read an env var to choose its name — instead it _exports_ the chosen name as `$BAR_NAME` to child scripts.

The external bar is launched as `sketchybar-external` (LaunchAgent `Program` = the real binary, `ProgramArguments[0]` = `sketchybar-external`), registering `git.felix.sketchybar-external`. SketchyBar exports that instance identity as `BAR_NAME` to its config and child scripts. `init.lua` reads `BAR_NAME` and passes its value to `sbar.set_bar_name` to address the matching daemon, with `sketchybar` as the fallback for a manual launch.

`SKETCHYBAR_PROFILE` selects the configuration style independently of the instance name. The default LaunchAgent sets `menubar`, loading `init/menubar.lua` on the internal display with media, space, and resource plugins. The external LaunchAgent sets `spaces-panel`, loading `init/spaces-panel.lua` on the external display with only the spaces plugin for that display's spaces and active space. Changing a profile does not change the messaging target.

`init.lua` dispatches with `require("init." .. profile)`, defaulting to `menubar` when the profile is unset. `sketchybarrc` is shared by both instances.

## Routing triggers to the right instance

A bare `sketchybar --trigger …` always hits `git.felix.sketchybar` (the internal menubar). Triggers for the external spaces panel use `sketchybar-external`:

- `event/dispatchers/now_playing.sh` re-invokes via `exec -a "$BAR_NAME"`, following the instance that loaded the media widgets (`sketchybar` for the internal menubar).
- `yabairc` sends `spaces_change` through `~/.scripts/sketchybar/trigger-bars.sh`, which attempts both instances independently and selects the external one with `exec -a sketchybar-external`. Either daemon may be absent during startup or undocking.

Yabai app, window, space, and display signals have labels so reloading `yabairc` replaces each registration. `window_focused` covers switching between windows of the same app.

## Coupling with yabai padding

Each display's yabai `bottom_padding` clears whatever bar lives there (`~/.scripts/yabai/apply-display-config.sh`): the internal display reclaims its bottom for the top menubar, and the external display reserves 66px for the bottom spaces panel. **Moving a bar's position means updating the matching yabai padding**, and vice-versa — nothing enforces it. The padding helper runs once on load, on `space_created`/`space_changed`, and on `display_added`/`display_removed`/`display_moved`, so new or relocated spaces receive their current monitor's padding.

## Display targeting

The spaces panel uses `option.BAR.BOTTOM.display`, a hardcoded monitor index (`2`) because sketchybar has no "secondary display" selector. Flip it to `1` if the external bar lands on the built-in; the index follows the System Settings arrangement, and the bar disappears when undocked.
