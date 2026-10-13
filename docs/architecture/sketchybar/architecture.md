# Sketchybar architecture

Two independent SketchyBar instances share one configuration tree:

| Instance               | Display    | Bar                 | LaunchAgent                         |
| ---------------------- | ---------- | ------------------- | ----------------------------------- |
| `sketchybar` (default) | built-in   | top, transparent    | `me.justinpxrk.sketchybar`          |
| `external`             | LG monitor | bottom, transparent | `me.justinpxrk.sketchybar-external` |

An instance has one global bar configuration, so separate instances allow different positions on the two displays. `init.lua` selects the profile from `SKETCHYBAR_PROFILE` and directs SbarLua to the external instance with `sbar.set_bar_name("external")` when needed.

## Instance routing

SketchyBar names its Mach service from `basename(argv[0])`: `git.felix.sketchybar` or `git.felix.external`. The external LaunchAgent uses `ProgramArguments[0] = external`; `$BAR_NAME` is exported to child scripts rather than selecting the instance itself.

A bare `sketchybar --trigger` reaches the default instance. The Now Playing dispatcher re-invokes the CLI with `exec -a "$BAR_NAME"`; yabai uses `~/.scripts/sketchybar/trigger-bars.sh` to reach both instances. Either trigger is best-effort while its daemon is absent. Named yabai signals are replaced on reload, including `window_focused` so switching between windows of the same app refreshes the indicators.

## Display targeting and padding

Each profile supplies its monitor's UUID to `spaces.setup`. Every successful refresh resolves that UUID to yabai's current arrangement index and uses the same index for the bar and its space row. The bar starts hidden. A successful refresh hides it when its monitor is disconnected instead of selecting the other monitor's spaces. Hardware replacement requires updating the profile UUID; the built-in UUID also appears in `yabai/apply-display-config.sh`.

Yabai padding remains coupled to the pill geometry: 8px top on the built-in, 47px bottom on the external, and 14px on the edges without bars. These values place tiled windows 14px from the current pills. `apply-display-config.sh` resolves displays by UUID and runs at startup, on space creation or switching, and on display addition, removal, or movement. Changes to bar geometry require matching padding changes.

## Space state and rendering

- `event/handlers/spaces.lua` coalesces signals for 50 ms and collects displays, spaces, windows, and the macOS front app asynchronously. Only one query batch runs at a time. Signals received before the batch starts are absorbed; signals during it discard that batch and request one later refresh, avoiding publication of a snapshot known to be stale. A failed yabai query preserves the current UI and releases the handler for the next event.
- `model/spaces.lua` contains the app ordering and title state, with no SketchyBar dependency. Recency is keyed by stable yabai space ID, while the displayed number follows the current space index. Each app appears once per space, focused apps move to the front, new apps append, and closed apps drop out. The space's window list also handles sticky windows. Departed spaces are pruned.
- `views/spaces.lua` owns item names, layout, colors, and the rendered cache. Content and theme changes update existing items. Changes to space indices or app counts rebuild the row in one SbarLua callback transaction, preserving region order.

Space boxes retain the outlined design: translucent `surface0`, 2px borders, 10px inner margins, and 5px between app glyphs. Visible spaces use a mauve border with a bright number and leading glyph; remaining glyphs use `overlay1`. Inactive spaces use a dim border and foreground. Empty spaces show only their number.

The active-app title pill has an app-font glyph and name on solid mauve, with the themed base color as its foreground. It shows the visible space's leading app on each display. A windowless front app on the focused space can name the pill without becoming a space glyph, even if that app has a window elsewhere. An empty space remembers its own last title when it loses focus; an unrelated empty space does not inherit that title. An unresolved title hides both its pill and spacer. The top bar also has a standalone Apple badge at the far left.

The top bar splits spaces around the notch: the title and first `floor(n/2)` spaces occupy `q`, with the remainder in `e`. Five spaces read `[title][1][2] | [3][4][5]`. The Apple badge is outside this group. Because `q` grows leftward, its items are added in reverse visual order; structural rebuilds re-add the title after the left spaces so it remains outermost. `notch_width = 244` is tuned for this panel. The external bar centers its title and spaces and omits the Apple badge.

Both bar backgrounds remain transparent. `plugins/theme.lua:setup(on_change)` refreshes the Catppuccin palette and repaints each profile's items on light/dark changes. Theme repainting uses cached space state and does not query yabai.

## Regression tests

`mise exec -- pnpm run test:sketchybar` runs the model, renderer, and coordinator against recorded SketchyBar calls and controlled async callbacks. The suite covers recency after space renumbering, monitor reordering and disconnection, windowless app titles, notch ordering, palette changes, failed queries, and signal bursts. It also runs in the Format/Lint workflow's Lint job.
