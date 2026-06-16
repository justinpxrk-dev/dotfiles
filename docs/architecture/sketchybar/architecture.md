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

Each display's yabai `bottom_padding` clears whatever bar lives there (`~/.scripts/yabai/apply-display-config.sh`): the built-in reclaims its bottom for the top bar, the external reserves 66px for the bottom bar. **Moving a bar's position means updating the matching yabai padding**, and vice-versa — nothing enforces it.

## Display targeting

`option.BAR.BOTTOM.display` is a hardcoded monitor index (`2`) because sketchybar has no "secondary display" selector. Flip it to `1` if the external bar lands on the built-in; the index follows the System Settings arrangement, and the bar disappears when undocked.

## Space indicators

There is no native sketchybar `space` item (that needs the SIP scripting addition), so `event/handlers/spaces.lua` draws each display's spaces itself: it filters yabai's spaces by `display` index (`M.DISPLAY`, set per profile) and re-queries `yabai -m query --spaces|--windows` on a custom `spaces_change` event that `yabairc` fans out to both bars (debounced 50 ms). Each space is a bracket box (number, divider, recent-app glyphs) — a dark `surface0` fill inside a thin (2px) border, with a uniform 10px gap throughout (border→number→divider→glyph→…→border). The active (visible) space has a **mauve** border and bright foreground number/glyphs, with its leading (active-app) glyph at full foreground and the other apps in a dimmer (`overlay1`) foreground; inactive spaces have a dim `surface1` border and a dimmer foreground throughout. The app pill shares the active mauve border.

- **Active-app pill.** The active app's name is _not_ shown in the space boxes — it lives in a separate singleton pill (an Apple-logo glyph plus the app name, both in the foreground color, inside the same dark-fill/mauve-border box) created once at init by `M.setup_app_pill`. Each display's pill shows **that display's** active app — the leading app of its visible space (captured in `M.render`), so it tracks that display's apps rather than the global frontmost app. A windowless front app on the _focused_ space (a Finder desktop) names the pill but is _not_ shown as a box glyph — the box shows only apps with windows; on an _unfocused_ display, where the global front app no longer identifies this display's space, the pill keeps its last app rather than blanking. The Apple logo is the `U+F8FF` codepoint in SF Pro (the sketchybar-app-font has no standalone Apple glyph). The pill leads the external bar's centered cluster (created before the space boxes, with a trailing spacer for uniform 10px spacing); on the top bar it sits in the `"q"` region (left of notch), mirroring the space row's `"e"` across the notch.
- **Flicker-free.** An unchanged set of space indices updates in place (`sbar.set`); create/destroy tears down and rebuilds the boxes in index order. Both commit as one SbarLua transaction. The app pill is a singleton, never torn down — only `set`.
- **Notch.** `position = "center"` lands dead-center behind the notch, so the top bar uses the notch-aware `position = "e"` ("right of notch") region for the space row and `"q"` ("left of notch") for the app pill; both anchors are derived from the live display center and the bar's `notch_width` (tuned on `option.BAR.TOP` so the row clears the physical notch by 10px), avoiding a hardcoded display-width offset. The external bar centers normally.
- **Theme.** `plugins/theme.lua:setup(on_change)` recolors boxes on light/dark — the external bar also repaints its themed background; the top bar stays pinned black. Because that background is always dark, the top bar sets `spaces.PIN_DARK_CHROME` so every color but the mauve border/accent stays on the dark (Mocha) palette in both modes — the dark fill and all text/icons never flip with light/dark (which would clash with the black bar). Only the active space's mauve border tracks the theme.

## Resource widgets (Stats mirror)

The top bar's right region mirrors [exelban/Stats](https://github.com/exelban/stats) menu-bar widgets rather than computing system metrics itself: `plugins/resources.lua` adds a sketchybar **`alias`** for each Stats menu-bar item, so every widget shows Stats' own live graph (and, for RAM, Stats' built-in `_state` status icon). Each alias is led by an SF Symbol icon (`constants/icon.lua`). Order left→right is CPU, GPU, RAM, Sensors — no labels. Only the top bar carries them; the external bar has none.

- **Alias plumbing.** An `alias` item's name _is_ its source menu-bar item's `"<owner>,<name>"` identifier; sketchybar re-captures the rendered item every `alias.update_freq` seconds (`constants/option.lua`, 2s). Discover the live names with `sketchybar --query default_menu_items`. Two couplings nothing checks (see `docs/ops/upgrade-hazards.md`): sketchybar needs **Screen Recording** permission to capture (so macOS shows a persistent recording indicator), and on **macOS 26** third-party items are owned by `Control Center` (not `Stats`), so the identifiers in `constants/item.lua` are OS-version- and Stats-config-specific.
- **RAM split.** RAM has Stats `oneView` off, so its status icon (`_state`) and chart are _separate_ menu-bar items — aliased separately, with the status icon led in front of the SF Symbol. CPU/GPU/Sensors are single merged items (icon + one alias).
- **Right-region order.** `"right"` items fill right-to-left in add order, so `plugins/resources.lua` lists the widgets left→right and adds them in reverse — CPU's icon, added last, lands left-most.
- **Spacing.** Each element carries a measured `padding_left` (in `plugins/resources.lua`) so the _visible_ gaps are uniform: ~20px between sections, ~10px within a section (icon→graph), and ~5px between RAM's `_state` dot and its icon. The values differ per element — some negative — because Stats bakes its own whitespace into each captured image (the `_state` dots are right-aligned in a wide box, already supplying ~20px) and the SF glyphs carry side-bearing. They were derived by pixel-measuring the rendered bar, so re-measure if Stats' rendering or the icons change.
- **Static, no repaint.** Stats colors the aliases; the SF Symbol icons take the always-dark palette (`colorschemes.get_default_color_options(true)`) because the top bar is pinned black and its theme handler never repaints them.
