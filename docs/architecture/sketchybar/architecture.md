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
- `yabairc`'s space/window/app signals call `~/.scripts/sketchybar/trigger-bars.sh`, which fires `spaces_change` at the default bar _and_ re-invokes the `external` bar via `exec -a external` (yabai isn't a sketchybar child, so the name is explicit) — both displays show their own spaces, so the event fans out to both.

## Coupling with yabai padding

Each display's yabai top/bottom padding is tuned so windows sit a uniform 14px from that display's bar pills (`~/.scripts/yabai/apply-display-config.sh`): 8px top on the built-in lands 14px below its top-bar pills, 47px bottom on the external lands 14px above its bottom-bar pills (the bar-less edges are a plain 14px). **Moving a bar's position means updating the matching yabai padding**, and vice-versa — nothing enforces it.

## Display targeting

`option.BAR.BOTTOM.display` is a hardcoded monitor index (`2`) because sketchybar has no "secondary display" selector. Flip it to `1` if the external bar lands on the built-in; the index follows the System Settings arrangement, and the bar disappears when undocked.

## The `model/` boundary

Pure domain logic lives under `model/`, kept apart from the bar wiring. A module belongs there only if it takes **no `require("sketchybar")`**, carries **no presentation concerns** (it speaks in domain values — app names, space indices — never glyphs or item names), and is **unit-testable as plain Lua** — the config's only sketchybar-free, testable zone. Its first occupant is `model/mru.lua`, the per-space **most-recently-used app ordering** that `event/handlers/spaces.lua` reads to lay out each space's app glyphs (most-recent first, deduped, with closed apps dropped); the handler drives it through `mru.promote` / `mru.reconcile` / `mru.prune`, while the ordering rules and their state live in the model. The renderer's own _view-mirror_ state — which space indices and glyph counts are currently materialized (`M.RENDERED` / `M.GLYPH_COUNT` / `M.ACTIVE`) — deliberately stays in the handler, because that is presentation bookkeeping, not domain state.

## Space indicators

There is no native sketchybar `space` item (that needs the SIP scripting addition), so `event/handlers/spaces.lua` draws each display's spaces itself: it filters yabai's spaces by `display` index (`M.DISPLAY`, set per profile) and re-queries `yabai -m query --spaces|--windows` on a custom `spaces_change` event that `yabairc` fans out to both bars (debounced 50 ms). Each space is a bracket box (number, divider, recent-app glyphs) — a dark `surface0` fill inside a thin (2px) border, with a uniform 10px gap throughout (border→number→divider→glyph→…→border). The active (visible) space has a **mauve** border and bright foreground number/glyphs, with its leading (active-app) glyph at full foreground and the other apps in a dimmer (`overlay1`) foreground; inactive spaces have a dim `surface1` border and a dimmer foreground throughout. The app pill shares the active mauve border.

- **Active-app pill.** The active app's name is _not_ shown in the space boxes — it lives in a separate singleton pill (an Apple-logo glyph plus the app name, both in the foreground color, inside the same dark-fill/mauve-border box) created once at init by `M.setup_app_pill`. Each display's pill shows **that display's** active app — the leading app of its visible space (captured in `M.render`), so it tracks that display's apps rather than the global frontmost app. A windowless front app on the _focused_ space (a Finder desktop) names the pill but is _not_ shown as a box glyph — the box shows only apps with windows; on an _unfocused_ display, where the global front app no longer identifies this display's space, the pill keeps its last app rather than blanking. The Apple logo is the `U+F8FF` codepoint in SF Pro (the sketchybar-app-font has no standalone Apple glyph). The pill leads the external bar's centered cluster (created before the space boxes, with a trailing spacer for uniform 10px spacing); on the top bar it is the left-most item of the `"q"` (left-of-notch) group and counts toward the notch split (see **Notch**).
- **Flicker-free.** An unchanged set of space indices updates in place (`sbar.set`); create/destroy tears down and rebuilds the boxes. Both commit as one SbarLua transaction. The app pill is a singleton on the external bar (never torn down — only `set`); on the split top bar it is re-added after the left spaces on each structural rebuild so it stays left-most, with `M.app_title` restoring its app across the rebuild.
- **Notch.** `position = "center"` lands dead-center behind the notch, so the top bar splits its row across the two notch-aware regions: the active-app pill plus the first `floor(n/2)` spaces (by sorted index) sit in `"q"` ("left of notch") and the rest in `"e"` ("right of notch"), balanced around the notch _including_ the pill (so 5 spaces give `[pill][1][2] | [3][4][5]`). `"q"` stacks right-to-left, so the left boxes are added in reverse to read the same left-to-right as the right side, and the pill is re-added after them to stay left-most. Both anchors are derived from the live display center and the bar's `notch_width` (tuned on `option.BAR.TOP` so the row clears the physical notch by 10px), avoiding a hardcoded display-width offset. The external bar has no notch, so it leaves `M.POSITION_LEFT` unset and centers the whole row.
- **Theme.** `plugins/theme.lua:setup(on_change)` recolors on light/dark — both bars repaint their themed background (`colorschemes.get_bar_color_options()`) and recolor their space boxes, glyphs, and text from the live palette (Mocha in dark, Latte in light). The active space's **mauve** border is the accent; inactive boxes use a dim `surface1` border.
