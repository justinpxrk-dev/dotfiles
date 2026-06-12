# Sketchybar architecture

Two independent sketchybar instances run at once, one per display:

| Instance               | Display           | Bar                 | LaunchAgent                         |
| ---------------------- | ----------------- | ------------------- | ----------------------------------- |
| `sketchybar` (default) | built-in (`main`) | top, menu-bar style | `me.justinpxrk.sketchybar`          |
| `external`             | external (LG)     | bottom, floating    | `me.justinpxrk.sketchybar-external` |

A single instance has one global `bar` config (position, height, …) applied to every display it draws on, so a top bar on one screen and a bottom bar on another is impossible within one instance — hence two.

## How an instance is named and addressed

sketchybar derives its identity from **`basename(argv[0])`** and registers a mach bootstrap service `git.felix.<argv[0]>` (default `git.felix.sketchybar`); the CLI and SbarLua reach a bar by looking that name up. It does **not** read an env var to choose its name — instead it _exports_ the chosen name as `$BAR_NAME` to child scripts.

So the external bar is launched as `external` (LaunchAgent `Program` = the real binary, `ProgramArguments[0]` = `external`), registering `git.felix.external`. Its config matches that port two ways:

- `SKETCHYBAR_PROFILE=external` (set by the LaunchAgent) makes `init.lua` load `init/external.lua` instead of `init/topbar.lua`.
- `sbar.set_bar_name("external")` repoints SbarLua — which otherwise always targets `git.felix.sketchybar` — at the external port.

`init.lua` is just that dispatcher, so `sketchybarrc` is unchanged and shared by both instances.

## Routing triggers to the right instance

A bare `sketchybar --trigger …` always hits `git.felix.sketchybar` (the default/top bar). Items on the external bar therefore need their triggers re-invoked under `external`:

- `event/dispatchers/now_playing.sh` re-invokes via `exec -a "$BAR_NAME"` (the daemon exported `BAR_NAME=external` to it).
- `yabairc`'s `spaces_change` signals use `exec -a external …` (yabai isn't a sketchybar child, so the name is explicit).

## Coupling with yabai padding

Each display's yabai `bottom_padding` clears whatever bar lives there (`~/.scripts/yabai/apply-display-config.sh`): the built-in reclaims its bottom for the top bar, the external reserves 66px for the bottom bar. **Moving a bar's position means updating the matching yabai padding**, and vice-versa — nothing enforces it.

## Display targeting

`option.BAR.BOTTOM.display` is a hardcoded monitor index (`2`) because sketchybar has no "secondary display" selector. Flip it to `1` if the external bar lands on the built-in; the index follows the System Settings arrangement, and the bar disappears when undocked.
