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

## markdown-it pin (pnpm override vs. markdownlint-cli2)

`markdownlint-cli2` pins `markdown-it` to an exact version (`14.1.1` as of `0.22.1`), and `14.1.1` carries a quadratic-complexity DoS in the smartquotes rule ([GHSA-6v5v-wf23-fmfq](https://github.com/advisories/GHSA-6v5v-wf23-fmfq) / CVE-2026-48988, fixed in `14.2.0`). `pnpm-workspace.yaml` carries an `overrides` entry lifting `markdown-it@<14.2.0` to `>=14.2.0` so the patched release is what actually installs.

**Failure mode:** bump `markdownlint-cli2` to a release whose own `markdown-it` pin is already `>=14.2.0` and the override becomes dead weight — harmless, but it silently masks the upstream pin and keeps forcing `markdown-it` even if a future `markdownlint-cli2` deliberately holds an older line for compatibility.

**On a markdownlint-cli2 upgrade:**

1. Check the new pin: `npm view markdownlint-cli2@<version> dependencies.markdown-it`.
2. If it is already `>=14.2.0`, drop the `markdown-it` override from `pnpm-workspace.yaml` and re-run `pnpm install`.
3. Re-run `pnpm run lint:md` to confirm markdownlint still parses cleanly under the resolved `markdown-it`.

## Zen Browser transparency (userChrome overrides + profile pref)

The Zen chrome css (`Library/Application Support/zen/Profiles/Default User/chrome/`) layers personal overrides over the Catppuccin zen submodule that target Zen's private internals: the `#zen-toolbar-background` layer inside `hbox#titlebar`, the `--zen-main-browser-background[-toolbar]` variables, the `--toolbar-bgcolor` wash, and the `about:blank` page Zen loads for empty tabs. None of this is API — a Zen update can rename or restructure any of it (verified against Zen `1.20.2b`).

**Failure mode:** after a Zen update the window goes opaque, or loses its Catppuccin tint, with no error anywhere — userChrome/userContent still load fine.

Website transparency has a second, profile-local leg: the Zen Internet extension only composites through to the window while `browser.tabs.allow_transparent_browser` is `true`. That pref is hand-set in about:config (Zen ships it `false`), lives in `prefs.js` outside chezmoi, and is not replayed on a fresh machine.

**On breakage or fresh setup:**

1. Web pages opaque: re-set `browser.tabs.allow_transparent_browser` to `true` in about:config and restart Zen.
2. Chrome surfaces opaque: re-locate the painted element or variable in the Zen bundle (`unzip -o /Applications/Zen.app/Contents/Resources/browser/omni.ja -d /tmp/zen-omni`, then grep `chrome/browser/content/browser/zen-styles/`) and adjust the overrides in the chrome css.
