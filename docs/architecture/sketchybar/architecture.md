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

A bare `sketchybar --trigger …` always hits `git.felix.sketchybar` (the default/top bar), so a dispatcher must route its triggers back to the bar that launched it (which exported its own name as `$BAR_NAME`):

- `event/dispatchers/now_playing.sh` re-invokes via `exec -a "$BAR_NAME"`. It is launched by the **top bar** (default instance), so `BAR_NAME=sketchybar` and the now-playing triggers reach that instance, where the pill lives.
- `yabairc`'s space/window/app signals call `~/.scripts/sketchybar/trigger-bars.sh`, which fires `spaces_change` at the default bar _and_ re-invokes the `external` bar via `exec -a external` (yabai isn't a sketchybar child, so the name is explicit) — both displays show their own spaces, so the event fans out to both.

## Coupling with yabai padding

Each display's yabai `bottom_padding` clears whatever bar lives there (`~/.scripts/yabai/apply-display-config.sh`): the built-in reclaims its bottom for the top bar, the external reserves 66px for the bottom bar. **Moving a bar's position means updating the matching yabai padding**, and vice-versa — nothing enforces it.

## Display targeting

`option.BAR.BOTTOM.display` is a hardcoded monitor index (`2`) because sketchybar has no "secondary display" selector. Flip it to `1` if the external bar lands on the built-in; the index follows the System Settings arrangement, and the bar disappears when undocked.

## Space indicators

There is no native sketchybar `space` item (that needs the SIP scripting addition), so `event/handlers/spaces.lua` draws each display's spaces itself: it filters yabai's spaces by `display` index (`M.DISPLAY`, set per profile) and re-queries `yabai -m query --spaces|--windows` on a custom `spaces_change` event that `yabairc` fans out to both bars (debounced 50 ms). Each space is a bracket box (number, divider, recent-app glyphs) — a dark `surface0` fill inside a thin (2px) border, with a uniform 10px gap throughout (border→number→divider→glyph→…→border). The active (visible) space has a **mauve** border and bright foreground number/glyphs, with its leading (active-app) glyph at full foreground and the other apps in a dimmer (`overlay1`) foreground; inactive spaces have a dim `surface1` border and a dimmer foreground throughout. The app pill shares the active mauve border.

- **Active-app pill.** The active app is _not_ named in the space boxes — it lives in its own two-pill cluster: an **Apple badge** (the Apple glyph, `U+1008FA` in SF Pro — the sketchybar-app-font has no standalone Apple logo) followed by a **title pill** carrying the active app's app-font icon glyph (the same source as the space-box glyphs) plus its name. Both are "system pills" — a solid **mauve** box with **knockout** content: the glyph and text take the bar's _own background_ colour (`colorschemes.get_bar_background`: pure black on the pinned top bar, the themed `BACKGROUND` role on the external bar), so they read as cutouts and the cluster stands clearly apart from the surface-filled space pills. Each display's cluster shows **that display's** active app — the leading app of its visible space (captured in `M.render`), so it tracks that display's apps rather than the global frontmost app. A windowless front app on the _focused_ space (a Finder desktop) names the pill but is _not_ shown as a box glyph; on an _unfocused_ display, where the global front app no longer identifies this display's space, the cluster keeps its last app (`M.app_title`) rather than blanking. The cluster leads the external bar's centered row; on the top bar it is the left-most item of the `"q"` (left-of-notch) group and counts toward the notch split (see **Notch**).
- **Flicker-free.** An unchanged set of space indices updates in place (`sbar.set`); create/destroy tears down and rebuilds the boxes. Both commit as one SbarLua transaction. The app pill is a singleton on the external bar (never torn down — only `set`); on the split top bar it is re-added after the left spaces on each structural rebuild so it stays left-most, with `M.app_title` restoring its app across the rebuild.
- **Notch.** `position = "center"` lands dead-center behind the notch, so the top bar splits its row across the two notch-aware regions: the active-app cluster (Apple badge + title pill) plus the first `floor((n-1)/2)` spaces (by sorted index) sit in `"q"` ("left of notch") and the rest in `"e"` ("right of notch"), balanced around the notch _including_ both system pills (so 5 spaces give `[Apple][title][1][2] | [3][4][5]`; counting left items incl. pills vs right, the split runs (2,1), (2,2), (3,2), (3,3), (4,3), (4,4)…). `"q"` stacks right-to-left, so the left boxes are added in reverse to read the same left-to-right as the right side, and the cluster is re-added after them to stay left-most. Both anchors are derived from the live display center and the bar's `notch_width` (tuned on `option.BAR.TOP` so the row clears the physical notch by 10px), avoiding a hardcoded display-width offset. The external bar has no notch, so it leaves `M.POSITION_LEFT` unset and centers the whole row.
- **Theme.** `plugins/theme.lua:setup(on_change)` recolors boxes on light/dark — the external bar also repaints its themed background; the top bar stays pinned black. Because that background is always dark, the top bar sets `spaces.PIN_DARK_CHROME` so every color but the mauve border/accent stays on the dark (Mocha) palette in both modes — the dark fill and all text/icons never flip with light/dark (which would clash with the black bar). Only the active space's mauve border tracks the theme.

## Resource widgets (Stats mirror)

The top bar's right region mirrors [exelban/Stats](https://github.com/exelban/stats) menu-bar widgets rather than computing system metrics itself: `plugins/resources.lua` adds a sketchybar **`alias`** for each Stats menu-bar item, so every widget shows Stats' own live graph (and, for RAM, Stats' built-in `_state` status icon). Each alias is led by an SF Symbol icon (`constants/icon.lua`). Order left→right is CPU, GPU, RAM, Sensors — no labels, all four framed together as a single **Stats pill**. Only the top bar carries them; the external bar has none.

- **Alias plumbing.** An `alias` item's name _is_ its source menu-bar item's `"<owner>,<name>"` identifier; sketchybar re-captures the rendered item every `alias.update_freq` seconds (`constants/option.lua`, 2s). Discover the live names with `sketchybar --query default_menu_items`. Two couplings nothing checks (see `docs/ops/upgrade-hazards.md`): sketchybar needs **Screen Recording** permission to capture (so macOS shows a persistent recording indicator), and on **macOS 26** third-party items are owned by `Control Center` (not `Stats`), so the identifiers in `constants/item.lua` are OS-version- and Stats-config-specific.
- **RAM split.** RAM has Stats `oneView` off, so its status icon (`_state`) and chart are _separate_ menu-bar items — aliased separately, with the status icon led in front of the SF Symbol. CPU/GPU/Sensors are single merged items (icon + one alias).
- **Right-region order.** `"right"` items fill right-to-left in add order, so `plugins/resources.lua` lists the widgets left→right and adds them in reverse — CPU's icon, added last, lands left-most. The inter-section spacers carry no `position`, so the add loop forces `"right"` on every item or they would land in the default region and collapse the gaps.
- **Unit (group bracket).** Each section carries a `group`; every section sharing a group is framed by one bracket spanning all its members — here a single `STATS_PILL` over the four widgets. The bracket reuses the inactive space box's surface fill + border (`colorschemes.get_space_color_options(false, true)` on the always-dark palette), so the Stats pill reads as a sibling of the space pills; the inter-widget gap spacers sit _inside_ its span, framed by the same fill. The rightmost item (Sensors) is followed by a trailing spacer that does double duty: it un-pins Sensors from the bar's right padding so its right inset takes effect (a `padding_right` on the bar-edge-pinned rightmost item is otherwise a no-op), and it sets a 10px gap from the macOS screen-recording indicator dot that overlaps the far-right corner. Pulling Stats' own per-module chart frame _off_ (a Stats pref, not in these dotfiles) keeps the pill from framing a frame — see `docs/ops/upgrade-hazards.md`.
- **Spacing.** Each element carries measured `ipad_l`/`ipad_r` (in `plugins/resources.lua`) so the _visible_ insets/gaps are uniform: ~10px border insets, ~10px between the widgets within the pill, and ~5px between RAM's `_state` dot and its icon. The values differ per element — several negative — because Stats bakes its own whitespace into each captured image (the right-aligned `_state` dots; the chart and Sensors images' trailing margin) and the SF glyphs carry side-bearing, so a literal 10px renders as anything from 0 to 19px. They were derived by pixel-measuring the rendered pill, so re-measure if Stats' rendering or the icons change.
- **Static, no repaint.** Stats colors the aliases; the SF Symbol icons and the unit bracket take the always-dark palette (`colorschemes.get_default_color_options(true)` / `get_space_color_options(false, true)`) because the top bar is pinned black and its theme handler never repaints them.
