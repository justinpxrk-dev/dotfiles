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

## Zen Browser transparency (userChrome overrides + profile pref)

The Zen chrome css (`Library/Application Support/zen/Profiles/Default User/chrome/`) layers personal overrides over the Catppuccin zen submodule that target Zen's private internals: the `#zen-toolbar-background` layer inside `hbox#titlebar`, the `--zen-main-browser-background[-toolbar]` variables, the `--toolbar-bgcolor` wash, and the `about:blank` page Zen loads for empty tabs. None of this is API — a Zen update can rename or restructure any of it (verified against Zen `1.20.2b`).

**Failure mode:** after a Zen update the window goes opaque, or loses its Catppuccin tint, with no error anywhere — userChrome/userContent still load fine.

Website transparency has a second, profile-local leg: the Zen Internet extension only composites through to the window while `browser.tabs.allow_transparent_browser` is `true`. That pref is hand-set in about:config (Zen ships it `false`), lives in `prefs.js` outside chezmoi, and is not replayed on a fresh machine.

**On breakage or fresh setup:**

1. Web pages opaque: re-set `browser.tabs.allow_transparent_browser` to `true` in about:config and restart Zen.
2. Chrome surfaces opaque: re-locate the painted element or variable in the Zen bundle (`unzip -o /Applications/Zen.app/Contents/Resources/browser/omni.ja -d /tmp/zen-omni`, then grep `chrome/browser/content/browser/zen-styles/`) and adjust the overrides in the chrome css.
