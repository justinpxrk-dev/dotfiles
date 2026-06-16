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

## markdownlint-cli2 exact pins (pnpm overrides vs. transitive DoS)

`markdownlint-cli2` pins several dependencies to exact versions, and two of those pins (as of `0.22.1`) carry quadratic-complexity DoS advisories. `pnpm-workspace.yaml` carries one `overrides` entry per pin, lifting each to its patched release so the fixed version is what actually installs:

- **markdown-it** — pinned to `14.1.1`; DoS in the smartquotes rule ([GHSA-6v5v-wf23-fmfq](https://github.com/advisories/GHSA-6v5v-wf23-fmfq) / CVE-2026-48988, fixed in `14.2.0`; Dependabot alert #1). Override: `markdown-it@<14.2.0` → `>=14.2.0`.
- **js-yaml** — pinned to `4.1.1`; DoS in merge-key handling via repeated aliases ([GHSA-h67p-54hq-rp68](https://github.com/advisories/GHSA-h67p-54hq-rp68) / CVE-2026-53550, fixed in `4.2.0`; Dependabot alert #2). Override: `js-yaml@<4.2.0` → `>=4.2.0`.

**Failure mode:** bump `markdownlint-cli2` to a release whose own pin is already at or past the patched version and that override becomes dead weight — harmless, but it silently masks the upstream pin and keeps forcing the dependency even if a future `markdownlint-cli2` deliberately holds an older line for compatibility.

**On a markdownlint-cli2 upgrade:**

1. Check the new pins: `npm view markdownlint-cli2@<version> dependencies.markdown-it dependencies.js-yaml`.
2. For any pin already at or past its patched version, drop the matching override from `pnpm-workspace.yaml` and re-run `pnpm install`.
3. Re-run `pnpm run lint:md` to confirm markdownlint still parses cleanly under the resolved dependencies.

## GitHub Actions SHA pins (no Dependabot to bump them)

Third-party actions in `.github/workflows/` are pinned to full commit SHAs with the version in a trailing comment (CodeQL `actions/unpinned-tag`, CWE-829 supply-chain hardening — a mutable tag like `@v5` can be repointed at malicious code). First-party `actions/*` (e.g. `actions/checkout`) are exempt and stay on version tags. Current pins:

| Action                 | SHA                                        | Version   |
| ---------------------- | ------------------------------------------ | --------- |
| `jdx/mise-action`      | `1648a7812b9aeae629881980618f079932869151` | `v4.0.1`  |
| `astral-sh/setup-uv`   | `d4b2f3b6ecc6e67c4457f6d3e41ec42d3d0fcb86` | `v5.4.2`  |
| `dorny/paths-filter`   | `d1c1ffe0248fe513906c8e24db8ea791d46f8590` | `v3.0.3`  |
| `webfactory/ssh-agent` | `e83874834305fe9a4a2997156cb26c5de65a8555` | `v0.10.0` |

**Failure mode:** there is no Dependabot/Renovate config, so nothing bumps these — they are frozen until hand-updated, silently missing upstream security fixes. The trailing `# vX.Y.Z` comment is the only signal of how stale a pin is.

**To bump an action** (resolve the new tag to its commit, verify it comes from the canonical repo, then update SHA _and_ comment together):

```sh
git ls-remote https://github.com/<owner>/<repo> 'refs/tags/<tag>' 'refs/tags/<tag>^{}'
```

Use the dereferenced (`^{}`) commit SHA for annotated tags; the bare ref already is the commit for lightweight tags.

## Sketchybar space indicators (app-font icon map + yabai display indices)

The per-display space boxes (`dot_config/sketchybar/event/handlers/spaces.lua`) lean on two things nothing checks:

1. **The generated app-font icon map.** `helpers/app_icons.lua` `dofile`s `~/.config/sketchybar/helpers/icon_map.lua`, installed by `install_sketchybar_app_font()` in `git/install-submodules.sh` (`pnpm run build:install`). A sketchybar-app-font upgrade regenerates that map; if upstream ever changes its shape (today `return { ["App"] = ":glyph:" }`) or the build stops emitting it, every app falls back to `:default:` — or the bar errors at load if the file is missing. Reinstall the font submodule and the map together.
2. **Display indices.** Each instance filters spaces by yabai `display` index (`spaces.DISPLAY` = 1 built-in / 2 external) and must agree with the matching bar's `option.BAR.*.display`. Both reshuffle on dock/undock the same way the bar already does — if the bars land on the wrong screens, the space rows do too.
3. **Notch clearance.** The top bar anchors its space row with the notch-aware `position = "e"` ("right of notch") region (`init/topbar.lua`), whose anchor sketchybar computes as ≈ `display_center + notch_width/2`. The `notch_width` (`244`, on `option.BAR.TOP`) is tuned so the first box clears the physical notch by 10px — measured live via `swift` + `NSScreen.auxiliaryTopRightArea` (notch right edge ~1197pt on the ~2160pt-wide built-in, a ~234pt centered notch). Two upgrade hazards, neither flagged at apply time: (a) the `q`/`e` position names are flagged **experimental** upstream — a sketchybar upgrade that renames/removes them breaks the anchor (the row would jump to a corner); re-check against the [item docs](https://felixkratz.github.io/SketchyBar/config/items) after `brew upgrade sketchybar`. (b) `notch_width` is a point value, so a built-in resolution/scaling change rescales the physical notch's point-width and the 10px gap drifts — re-measure the notch edge and re-tune `notch_width`. This is still far less brittle than an absolute offset: the dominant ~950pt half-display term is recomputed by sketchybar, not hardcoded.

**Failure mode:** after a font upgrade, app glyphs all show the default icon (or the bar drops on load); after a display reshuffle, a bar shows the other display's spaces. Neither is flagged at `chezmoi apply` time.

Unrelated to upgrades but worth knowing: `yabairc` fans `space_*` / `window_*` / `application_front_switched` out to **both** bars on every change. The handler debounces (`sbar.delay` 50 ms); if it ever feels heavy, drop the `window_moved` signal or widen the debounce.

## Sketchybar resource widgets (Stats menu-bar aliases)

The top bar's resource widgets (`dot_config/sketchybar/plugins/resources.lua`) are sketchybar `alias` items that mirror [Stats](https://github.com/exelban/stats) menu-bar items — they render Stats' own graphs, so the cluster goes blank if any of three unchecked couplings breaks:

1. **Screen Recording permission.** sketchybar captures the live menu bar to draw an alias, which needs Screen Recording permission (System Settings → Privacy & Security → Screen Recording → SketchyBar) and then a full restart of the bar (`launchctl kickstart -k gui/$(id -u)/me.justinpxrk.sketchybar`, likewise `-external`). Without it, `sketchybar --query default_menu_items` returns `Screen Recording Permissions not given` and every alias is blank. A consequence: macOS shows a persistent screen-recording indicator while the bar runs.
2. **Alias names are OS- and Stats-specific.** An alias name must equal its source's `"<owner>,<name>"`. On macOS 26 third-party items are owned by `Control Center` (e.g. `Control Center,CPU`), not `Stats` — a macOS major upgrade, a Stats update, or toggling a module's widget type / `oneView` can rename them. Re-discover with `sketchybar --query default_menu_items` and update `constants/item.lua`. The current map assumes CPU/GPU/Sensors enabled (single merged item) and RAM with `oneView` off (separate `_state` + bar chart).
3. **Stats must be running** with those modules enabled; it's a Homebrew cask (`dot_Brewfile`), but the menu-bar items only exist while Stats runs.

**Failure mode:** the resource cluster is blank or partial with no error at `chezmoi apply` (and none in `~/Library/Logs/me.justinpxrk/sketchybar.log`) — usually a revoked Screen Recording permission after an OS update, or alias names that drifted.

## Zen Browser transparency (userChrome overrides + profile pref)

The Zen chrome css (`Library/Application Support/zen/Profiles/Default User/chrome/`) layers personal overrides over the Catppuccin zen submodule that target Zen's private internals: the `#zen-toolbar-background` layer inside `hbox#titlebar`, the `--zen-main-browser-background[-toolbar]` variables, the `--toolbar-bgcolor` wash, and the `about:blank` page Zen loads for empty tabs. None of this is API — a Zen update can rename or restructure any of it (verified against Zen `1.20.2b`).

**Failure mode:** after a Zen update the window goes opaque, or loses its Catppuccin tint, with no error anywhere — userChrome/userContent still load fine.

Website transparency has a second, profile-local leg: the Zen Internet extension only composites through to the window while `browser.tabs.allow_transparent_browser` is `true`. That pref is hand-set in about:config (Zen ships it `false`), lives in `prefs.js` outside chezmoi, and is not replayed on a fresh machine.

**On breakage or fresh setup:**

1. Web pages opaque: re-set `browser.tabs.allow_transparent_browser` to `true` in about:config and restart Zen.
2. Chrome surfaces opaque: re-locate the painted element or variable in the Zen bundle (`unzip -o /Applications/Zen.app/Contents/Resources/browser/omni.ja -d /tmp/zen-omni`, then grep `chrome/browser/content/browser/zen-styles/`) and adjust the overrides in the chrome css.
