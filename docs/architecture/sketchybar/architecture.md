# Sketchybar architecture

Two independent sketchybar instances run at once, one per display:

| Instance               | Display           | Bar                 | LaunchAgent                         |
| ---------------------- | ----------------- | ------------------- | ----------------------------------- |
| `sketchybar` (default) | built-in (`main`) | top, menu-bar style | `me.justinpxrk.sketchybar`          |
| `external`             | external (LG)     | bottom, transparent | `me.justinpxrk.sketchybar-external` |

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

- **Active-app pill.** The active app is _not_ named in the space boxes — it lives in a **title pill** carrying the active app's app-font icon glyph (the same source as the space-box glyphs) plus its name, accompanied (on the top bar only) by a standalone **Apple badge** (the Apple glyph, `U+1008FA` in SF Pro — the sketchybar-app-font has no standalone Apple logo) pinned at the bar's far-left edge, apart from the title pill. Both are "system pills" — a solid **mauve** box with **knockout** content: the glyph and text take the bar's own `BACKGROUND` colour (`colorschemes.get_bar_background`), so they read as cutouts and stand clearly apart from the surface-filled space pills. The title pill shows **that display's** active app — the leading app of its visible space (captured in `M.render`), so it tracks that display's apps rather than the global frontmost app. A windowless front app on the _focused_ space (a Finder desktop) names the pill but is _not_ shown as a box glyph; on an _unfocused_ display, where the global front app no longer identifies this display's space, the pill keeps its last app (`M.app_title`) rather than blanking. On the top bar the Apple badge sits in the far-left `"left"` region (`M.APPLE_POSITION`, before the now-playing pill) and the title pill leads the `"q"` (left-of-notch) group, counting toward the notch split (see **Notch**); on the external bar the badge is omitted (`M.APPLE_POSITION` unset) and the title pill leads the centered row.
- **Flicker-free.** An unchanged set of space indices updates in place (`sbar.set`); create/destroy tears down and rebuilds the boxes. Both commit as one SbarLua transaction. The app pill is a singleton on the external bar (never torn down — only `set`); on the split top bar it is re-added after the left spaces on each structural rebuild so it stays left-most, with `M.app_title` restoring its app across the rebuild.
- **Notch.** `position = "center"` lands dead-center behind the notch, so the top bar splits its row across the two notch-aware regions: the **title pill** plus the first `floor((n-1)/2)` spaces (by sorted index) sit in `"q"` ("left of notch") and the rest in `"e"` ("right of notch"), balanced around the notch _including_ the title pill (so 5 spaces give `[title][1][2] | [3][4][5]`; counting left items incl. the pill vs right, the split runs (2,1), (2,2), (3,2), (3,3), (4,3), (4,4)…). The standalone Apple badge is _not_ part of this split — it sits in the separate far-left `"left"` region (see **Active-app pill**). `"q"` stacks right-to-left, so the left boxes are added in reverse to read the same left-to-right as the right side, and the title pill is re-added after them to stay left-most. Both anchors are derived from the live display center and the bar's `notch_width` (tuned on `option.BAR.TOP` so the row clears the physical notch by 10px), avoiding a hardcoded display-width offset. The external bar has no notch, so it leaves `M.POSITION_LEFT` unset and centers the whole row.
- **Theme.** Both bars are **fully transparent** (`color = 0x00000000`), so their backgrounds are never repainted — only their items track light/dark. `plugins/theme.lua:setup(on_change)` refreshes the palette (`theme.refresh_palette`) and recolors the space boxes, glyphs, text, and pills from the live palette (Mocha in dark, Latte in light) on every switch. The active space's **mauve** border is the accent; inactive boxes use a dim `surface1` border.

## Resource widgets (Stats mirror)

The top bar's right region mirrors [exelban/Stats](https://github.com/exelban/stats) menu-bar widgets rather than computing system metrics itself: `plugins/resources.lua` adds a sketchybar **`alias`** for each Stats menu-bar item, so every widget shows Stats' own live graph (and, for RAM, Stats' built-in `_state` status icon). Each alias is led by an SF Symbol icon (`constants/icon.lua`). Order left→right is CPU, GPU, RAM, Sensors — no labels. Only the top bar carries them; the external bar has none.

- **Alias plumbing.** An `alias` item's name _is_ its source menu-bar item's `"<owner>,<name>"` identifier; sketchybar re-captures the rendered item every `alias.update_freq` seconds (`constants/option.lua`, 2s). Discover the live names with `sketchybar --query default_menu_items`. Two couplings nothing checks (see `docs/ops/upgrade-hazards.md`): sketchybar needs **Screen Recording** permission to capture (so macOS shows a persistent recording indicator), and on **macOS 26** third-party items are owned by `Control Center` (not `Stats`), so the identifiers in `constants/item.lua` are OS-version- and Stats-config-specific.
- **RAM split.** RAM has Stats `oneView` off, so its status icon (`_state`) and chart are _separate_ menu-bar items — aliased separately, with the status icon led in front of the SF Symbol. CPU/GPU/Sensors are single merged items (icon + one alias).
- **Right-region order.** `"right"` items fill right-to-left in add order, so `plugins/resources.lua` lists the widgets left→right and adds them in reverse — CPU's icon, added last, lands left-most.
- **Spacing.** Each element carries a measured `padding_left` (in `plugins/resources.lua`) so the _visible_ gaps are uniform: ~20px between sections, ~10px within a section (icon→graph), and ~5px between RAM's `_state` dot and its icon. The values differ per element — some negative — because Stats bakes its own whitespace into each captured image (the `_state` dots are right-aligned in a wide box, already supplying ~20px) and the SF glyphs carry side-bearing. They were derived by pixel-measuring the rendered bar, so re-measure if Stats' rendering or the icons change.
- **Themed, repainted.** Stats colors the aliases; the SF Symbol icons take the live theme color (`colorschemes.get_default_color_options()`) and are repainted on light/dark by `event/handlers/resources.lua:theme_change_handler` (wired into the top bar's `on_change`), like the rest of the bar.
