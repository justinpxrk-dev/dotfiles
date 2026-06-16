# upgrade-hazards.md

Things that break silently when an upstream tool is upgraded — nothing here is caught by a test or lint, so scan this before `brew upgrade`, or when something stops working right after one.

## Lua version coupling (sketchybar + LuaRocks)

The Catppuccin palette reaches sketchybar as a LuaRocks rock loaded by SbarLua's embedded Lua. That ties the bar to a single Lua `major.minor`, which appears in three places that must all agree:

1. **What the bar runs** — `dot_config/sketchybar/lib/SbarLua/makefile` pins
   `LUA_DIR=lua-5.5.0`, statically linked into `sketchybar.so`.
2. **Where the rock installs** — Homebrew's `lua` version decides the tree:
   `~/.luarocks/share/lua/<major.minor>/`.
3. **Where the bar looks** — `dot_config/sketchybar/executable_sketchybarrc` adds
   `~/.luarocks/share/lua/5.5/` to `package.path`.

All three are **5.5** today (Homebrew `lua` is `5.5.0`, matching SbarLua's pin).

**Failure mode:** bump Homebrew `lua` to a new minor (say 5.6) and the rock reinstalls under `lua/5.6/`, while `sketchybarrc` still points at `lua/5.5/`. `require("catppuccin")` then fails and the bar errors or drops its colors — with nothing flagged at `chezmoi apply` time.

**On a Lua upgrade:**

1. Bump the `5.5` in `executable_sketchybarrc`'s `package.path` to the new `major.minor`.
2. Reinstall the rock into the new tree: `luarocks install --local catppuccin`.
3. Keep SbarLua's `LUA_DIR` pin aligned with Homebrew's `lua`.

## Sketchybar space indicators (app-font icon map + yabai display indices)

The per-display space boxes (`dot_config/sketchybar/event/handlers/spaces.lua`) lean on two things nothing checks:

1. **The generated app-font icon map.** `helpers/app_icons.lua` `dofile`s `~/.config/sketchybar/helpers/icon_map.lua`, installed by `install_sketchybar_app_font()` in `git/install-submodules.sh` (`pnpm run build:install`). A sketchybar-app-font upgrade regenerates that map; if upstream ever changes its shape (today `return { ["App"] = ":glyph:" }`) or the build stops emitting it, every app falls back to `:default:` — or the bar errors at load if the file is missing. Reinstall the font submodule and the map together.
2. **Display indices.** Each instance filters spaces by yabai `display` index (`spaces.DISPLAY` = 1 built-in / 2 external) and must agree with the matching bar's `option.BAR.*.display`. Both reshuffle on dock/undock the same way the bar already does — if the bars land on the wrong screens, the space rows do too.
3. **Notch clearance.** The top bar anchors its space row with the notch-aware `position = "e"` ("right of notch") region (`init/topbar.lua`), whose anchor sketchybar computes as ≈ `display_center + notch_width/2`. The `notch_width` (`218`, on `option.BAR.TOP`) is tuned so the first box clears the physical notch by 10px — measured live via `swift` + `NSScreen.auxiliaryTopRightArea` (notch right edge ~1054pt on the ~1901pt-wide built-in, a ~206pt centered notch; `bracket.left = 955 + 0.5 × notch_width`). Two upgrade hazards, neither flagged at apply time: (a) the `q`/`e` position names are flagged **experimental** upstream — a sketchybar upgrade that renames/removes them breaks the anchor (the row would jump to a corner); re-check against the [item docs](https://felixkratz.github.io/SketchyBar/config/items) after `brew upgrade sketchybar`. (b) `notch_width` is a point value, so a built-in resolution/scaling change rescales the physical notch's point-width and the 10px gap drifts — re-measure the notch edge and re-tune `notch_width`. This is still far less brittle than an absolute offset: the dominant ~950pt half-display term is recomputed by sketchybar, not hardcoded.

**Failure mode:** after a font upgrade, app glyphs all show the default icon (or the bar drops on load); after a display reshuffle, a bar shows the other display's spaces. Neither is flagged at `chezmoi apply` time.

Unrelated to upgrades but worth knowing: `yabairc` fans `space_*` / `window_*` / `application_front_switched` out to **both** bars on every change. The handler debounces (`sbar.delay` 50 ms); if it ever feels heavy, drop the `window_moved` signal or widen the debounce.

## Sketchybar resource widgets (Stats menu-bar aliases)

The top bar's resource widgets (`dot_config/sketchybar/plugins/resources.lua`) are sketchybar `alias` items that mirror [Stats](https://github.com/exelban/stats) menu-bar items — they render Stats' own graphs, so the cluster goes blank if any of four unchecked couplings breaks:

1. **Screen Recording permission.** sketchybar captures the live menu bar to draw an alias, which needs Screen Recording permission (System Settings → Privacy & Security → Screen Recording → SketchyBar) and then a full restart of the bar (`launchctl kickstart -k gui/$(id -u)/me.justinpxrk.sketchybar`, likewise `-external`). Without it, `sketchybar --query default_menu_items` returns `Screen Recording Permissions not given` and every alias is blank. A consequence: macOS shows a persistent screen-recording indicator while the bar runs.
2. **Alias names are OS- and Stats-specific.** An alias name must equal its source's `"<owner>,<name>"`. On macOS 26 third-party items are owned by `Control Center` (e.g. `Control Center,CPU`), not `Stats` — a macOS major upgrade, a Stats update, or toggling a module's widget type / `oneView` can rename them. Re-discover with `sketchybar --query default_menu_items` and update `constants/item.lua`. The current map assumes CPU/GPU/Sensors enabled (single merged item) and RAM with `oneView` off (separate `_state` + bar chart).
3. **Stats must be running** with those modules enabled; it's a Homebrew cask (`dot_Brewfile`), but the menu-bar items only exist while Stats runs.
4. **Pill framing assumes frameless charts + a fixed recording-dot position.** The four Stats widgets are framed in one pill (`STATS_PILL`, `plugins/resources.lua`), so Stats' own per-module chart frame must be **off** — otherwise it's a frame inside the pill border (frame-in-frame), and it shifts the image dimensions the paddings were measured against. That toggle lives in Stats' prefs, **not** these dotfiles, so it is not replayed on a fresh machine — disable it per module in Stats after install. The Sensors right inset (inside the Stats pill) and the trailing `PILL_TRAIL` spacer are also tuned against the fixed screen position of the macOS screen-recording indicator dot (from coupling 1, it overlaps the bar's far-right corner); if that dot moves on an OS change, the 10px clearance drifts. Every per-element `ipad_l`/`ipad_r` is pixel-measured against Stats' baked image whitespace, so re-measure (screenshot + pixel-measure) if Stats' rendering changes.

**Failure mode:** the resource cluster is blank or partial with no error at `chezmoi apply` (and none in `~/Library/Logs/me.justinpxrk/sketchybar.log`) — usually a revoked Screen Recording permission after an OS update, or alias names that drifted. After a Stats reinstall the pills may also show a frame inside each pill until the per-module chart frame is turned back off.

## Zen Browser transparency (userChrome overrides + profile pref)

The Zen chrome css (`Library/Application Support/zen/Profiles/Default User/chrome/`) layers personal overrides over the Catppuccin zen submodule that target Zen's private internals: the `#zen-toolbar-background` layer inside `hbox#titlebar`, the `--zen-main-browser-background[-toolbar]` variables, the `--toolbar-bgcolor` wash, and the `about:blank` page Zen loads for empty tabs. None of this is API — a Zen update can rename or restructure any of it (verified against Zen `1.20.2b`).

**Failure mode:** after a Zen update the window goes opaque, or loses its Catppuccin tint, with no error anywhere — userChrome/userContent still load fine.

Website transparency has a second, profile-local leg: the Zen Internet extension only composites through to the window while `browser.tabs.allow_transparent_browser` is `true`. That pref is hand-set in about:config (Zen ships it `false`), lives in `prefs.js` outside chezmoi, and is not replayed on a fresh machine.

**On breakage or fresh setup:**

1. Web pages opaque: re-set `browser.tabs.allow_transparent_browser` to `true` in about:config and restart Zen.
2. Chrome surfaces opaque: re-locate the painted element or variable in the Zen bundle (`unzip -o /Applications/Zen.app/Contents/Resources/browser/omni.ja -d /tmp/zen-omni`, then grep `chrome/browser/content/browser/zen-styles/`) and adjust the overrides in the chrome css.
