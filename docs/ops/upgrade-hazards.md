# upgrade-hazards.md

Things that break silently when an upstream tool is upgraded — nothing here is caught by a test or lint, so scan this before `brew upgrade`, or when something stops working right after one.

## Homebrew tap trust (Brewfile and cleanup)

Homebrew requires explicit trust for non-official formulae, casks, and commands by default. `HOMEBREW_REQUIRE_TAP_TRUST` is deprecated because it requests that default; leave it unset. Declare `trusted: true` on each fully qualified third-party formula in `dot_Brewfile` so Bundle grants trust before loading it. See [Tap Trust](https://docs.brew.sh/Tap-Trust) and [Brewfile trust declarations](https://docs.brew.sh/Brew-Bundle-and-Brewfile#trusted).

**Failure mode:** when `brew bundle cleanup` performs cleanup (with `--force` or after confirmation), it resets Homebrew's global trust store to the selected Brewfile's declarations. Trust granted manually or by a bootstrap script disappears if it is absent from that Brewfile; a file with no trust declarations clears every explicit trust entry.

When adding a third-party dependency, use its fully qualified name and `trusted: true` in `dot_Brewfile`. Declare only the individual formulae this setup uses. `spicetify-cli` comes from official `homebrew/core`, so it needs neither `spicetify/tap` nor a trust declaration.

After a trust-related failure, inspect `brew trust` and `brew untrust`, then run `brew bundle install --global` to restore the declared formula trust. Existing whole-tap trust is retained by an install; cleanup with this Brewfile narrows it to the declared formulae.

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

## markdownlint-cli2 dependency pins and compatibility

`markdownlint-cli2` 0.23.3 supports `js-yaml` 5 and `markdown-it` 15. Its dependency pins already include the fixes that required the previous `js-yaml` 4.2.0 and `markdown-it` 14.2.0 overrides, so those overrides are removed.

`markdownlint-cli2` still pins `smol-toml` to 1.8.0, which has a quadratic-time parsing denial-of-service vulnerability ([GHSA-r4xh-jqrq-34v2](https://github.com/advisories/GHSA-r4xh-jqrq-34v2), fixed in 1.9.0). `pnpm-workspace.yaml` overrides affected versions with `^1.9.0`, keeping the patch within the supported major. Remove this override once the linter's own pin includes the fix.

**Failure mode:** an override with only a lower bound can allow Dependabot to cross a dependency's major version while its parent remains unchanged. `markdownlint-cli2` 0.22.1 imports a default export from `js-yaml`, so replacing that dependency with version 5 crashes the linter before it checks any Markdown. Update the parent to a compatible release and keep any remaining security overrides within its supported dependency majors.

**On a markdownlint-cli2 upgrade:**

1. Check the new pins: `npm view markdownlint-cli2@<version> dependencies`.
2. Remove overrides whose fixes are already included upstream; bound any remaining overrides to compatible major versions and run `pnpm install`.
3. Run `pnpm run check` to verify the refreshed dependency tree and repository configuration together.

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

## Homebrew cask metadata and download failures on macOS CI

The macOS deploy workflows and startup benchmark refresh Homebrew with `brew update` before applying dotfiles. Runner images can contain stale cask metadata, while unversioned font downloads can change their installer filenames. On 2026-10-12, the cached `font-sf-pro` definition expected `SF Pro Fonts.pkg`, but Apple's download contained `SFProFonts.pkg`; the current [Homebrew cask definition](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/font/font-s/font-sf-pro.rb) already uses the new filename.

Keep the explicit metadata-refresh step in both deploy workflows and inside the startup benchmark's setup gate. Refresh metadata first when an installer artifact no longer matches a cask definition.

## Hyperfine JSON schema (startup benchmark)

The startup workflow reads [Hyperfine 2's JSON export](https://github.com/sharkdp/hyperfine/releases/tag/v2.0.0) from `results[0].summary.time_wall_clock.min` and `.mean`. These values are exported in seconds and multiplied by 1000 before reporting milliseconds; the startup limit remains `THRESHOLD_MS=200`. Hyperfine 1's `results[0].min` and `.mean` fields no longer exist.

After a Hyperfine major upgrade, inspect a fresh `--export-json` result and check the workflow's field paths and units before interpreting a reporting failure as a startup regression.

## Zen Browser transparency (userChrome overrides + profile pref)

The Zen chrome css (`Library/Application Support/zen/Profiles/Default User/chrome/`) layers personal overrides over the Catppuccin zen submodule that target Zen's private internals: the `#zen-toolbar-background` layer inside `hbox#titlebar`, the `--zen-main-browser-background[-toolbar]` variables, the `--toolbar-bgcolor` wash, and the `about:blank` page Zen loads for empty tabs. None of this is API — a Zen update can rename or restructure any of it (verified against Zen `1.20.2b`).

**Failure mode:** after a Zen update the window goes opaque, or loses its Catppuccin tint, with no error anywhere — userChrome/userContent still load fine.

Website transparency has a second, profile-local leg: the Zen Internet extension only composites through to the window while `browser.tabs.allow_transparent_browser` is `true`. That pref is hand-set in about:config (Zen ships it `false`), lives in `prefs.js` outside chezmoi, and is not replayed on a fresh machine.

**On breakage or fresh setup:**

1. Web pages opaque: re-set `browser.tabs.allow_transparent_browser` to `true` in about:config and restart Zen.
2. Chrome surfaces opaque: re-locate the painted element or variable in the Zen bundle (`unzip -o /Applications/Zen.app/Contents/Resources/browser/omni.ja -d /tmp/zen-omni`, then grep `chrome/browser/content/browser/zen-styles/`) and adjust the overrides in the chrome css.

## pnpm native binaries (mise backend)

`mise.toml` uses the `pnpm` shorthand, whose preferred backend is `aqua:pnpm/pnpm`. It downloads the standalone release executable directly. Keep this backend when updating pnpm. The previous `npm:pnpm` installation left a Node.js shim pointing at pnpm 12's install-time placeholder and crashed with `SyntaxError: Invalid or unexpected token` before local or CI commands ran. See [mise's pnpm registry entry](https://mise.jdx.dev/registry.html#pnpm).

After a backend change, run `mise install pnpm`, then check `mise tool pnpm`, `mise which pnpm`, and `mise exec -- pnpm --version`. The active executable should come from mise's `pnpm` installation, rather than `npm-pnpm`. Existing npm-backend installations can remain on disk; mise selects the backend declared by this repository.

CI jobs have separate checkouts and dependency installations. Both Format and Lint must run `pnpm install --frozen-lockfile` before package scripts; Lint also needs `uv sync --dev`. Installing dependencies in the Format job does not prepare the Lint job.
