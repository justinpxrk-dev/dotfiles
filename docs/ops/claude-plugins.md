# claude-plugins.md

Claude Code plugins. In `dot_claude/settings.json` the `enabledPlugins`, `extraKnownMarketplaces`, `agent`, and the `wozcode` feature toggles (`spinnerVerbs`, `statusLineLifetime`, `statusLineShare`, `attribution`) are version-controlled. Left untracked: the volatile UI-state keys WOZCODE writes into the same `wozcode` block (e.g. `desktopInstallNoticeShown`), plus the installed-plugin records and plugin code under `~/.claude/plugins/` (absolute paths + timestamps) — all re-created at runtime on each machine.

## Built-in plugins (lua-lsp, pyright-lsp)

From `claude-plugins-official`, which Claude Code knows by default. A fresh machine needs only the `enabledPlugins` entry plus a one-time `/plugin install <name>@claude-plugins-official`.

## WOZCODE (woz@wozcode-marketplace)

Third-party plugin ([`WithWoz/wozcode-plugin`](https://github.com/WithWoz/wozcode-plugin)) that swaps in custom tools to cut token cost/latency. Its marketplace isn't known by default and it needs a Woz account, so a fresh machine takes these manual steps (no script or lint enforces them):

1. `/plugin marketplace add WithWoz/wozcode-plugin`
2. `/plugin install woz@wozcode-marketplace` (confirm the exact `plugin@marketplace` id `/plugin` prints, in case upstream renames it).
3. Relaunch Claude Code, then `/woz-login` — browser auth writes tokens to `~/.claude/wozcode/`.
4. Mirror the `enabledPlugins`, `extraKnownMarketplaces`, `agent`, and the `wozcode` feature toggles (`spinnerVerbs`/`statusLineLifetime`/`statusLineShare`/`attribution`) Claude writes in `~/.claude/settings.json` back into `dot_claude/settings.json` (but not the volatile `wozcode` UI-state keys like `desktopInstallNoticeShown`), then `chezmoi apply` and confirm `chezmoi diff` is clean.

**Credential safety:** the `~/.claude/wozcode/` tokens are secrets — never `chezmoi add` or commit that directory. chezmoi only manages files you add, so the default is already safe; this is a reminder not to break it.

### Feature toggles (spinner verbs, status line, attribution)

WOZCODE's cosmetic features default to on, and its session hook re-asserts them into `~/.claude/settings.json` every session. To keep them off, the toggles must live in the **tracked** `wozcode` block — otherwise `chezmoi apply` strips them, the hook sees no override, and re-injects the defaults (the spinner-verb list and the `Co-Authored-By: WOZCODE` commit/PR line) on the next session. Set them with `/woz-settings` (or `scripts/settings-helper.js --set <key> false`), then mirror the resulting toggles into `dot_claude/settings.json`. Currently tracked off: `spinnerVerbs`, `statusLineLifetime`, `statusLineShare`, `attribution`. The master `statusLine` is left on, so session savings + tips still show.

## Caveats

- **Fresh-machine ordering:** `chezmoi apply` writes a `settings.json` naming `woz@wozcode-marketplace` and `agent: woz:code` before the plugin code and login exist — expect first-launch warnings and no `woz:code` agent until the manual steps above run.
- **Diff churn:** Claude Code writes runtime state into `~/.claude/settings.json` — the volatile `wozcode` UI-state keys (e.g. `desktopInstallNoticeShown`) and native keys like `effortLevel` — that `chezmoi apply` reverts, so `chezmoi diff` can show noise; ignore those. The exception is the `wozcode` feature toggles (`spinnerVerbs`/`statusLineLifetime`/`statusLineShare`/`attribution`), which are tracked precisely because reverting them silently re-enables the feature (see the feature-toggles note above).
