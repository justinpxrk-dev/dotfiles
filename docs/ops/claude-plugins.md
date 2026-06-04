# claude-plugins.md

Claude Code plugins. In `dot_claude/settings.json` the `enabledPlugins`,
`extraKnownMarketplaces`, and `agent` keys are version-controlled. Left
untracked: the `wozcode` block (UI state Claude rewrites, e.g.
`desktopInstallNoticeShown`), plus the installed-plugin records and plugin code
under `~/.claude/plugins/` (absolute paths + timestamps) — all re-created at
runtime on each machine.

## Built-in plugins (lua-lsp, pyright-lsp)

From `claude-plugins-official`, which Claude Code knows by default. A fresh
machine needs only the `enabledPlugins` entry plus a one-time
`/plugin install <name>@claude-plugins-official`.

## WOZCODE (woz@wozcode-marketplace)

Third-party plugin ([`WithWoz/wozcode-plugin`](https://github.com/WithWoz/wozcode-plugin))
that swaps in custom tools to cut token cost/latency. Its marketplace isn't
known by default and it needs a Woz account, so a fresh machine takes these
manual steps (no script or lint enforces them):

1. `/plugin marketplace add WithWoz/wozcode-plugin`
2. `/plugin install woz@wozcode-marketplace` (confirm the exact
   `plugin@marketplace` id `/plugin` prints, in case upstream renames it).
3. Relaunch Claude Code, then `/woz-login` — browser auth writes tokens to
   `~/.claude/wozcode/`.
4. Mirror the `enabledPlugins`, `extraKnownMarketplaces`, and `agent` keys
   Claude writes in `~/.claude/settings.json` back into
   `dot_claude/settings.json` (leave the `wozcode` block out), then
   `chezmoi apply` and confirm `chezmoi diff` is clean.

**Credential safety:** the `~/.claude/wozcode/` tokens are secrets — never
`chezmoi add` or commit that directory. chezmoi only manages files you add, so
the default is already safe; this is a reminder not to break it.

## Caveats

- **Fresh-machine ordering:** `chezmoi apply` writes a `settings.json` naming
  `woz@wozcode-marketplace` and `agent: woz:code` before the plugin code and
  login exist — expect first-launch warnings and no `woz:code` agent until the
  manual steps above run.
- **Diff churn:** Claude Code writes its own runtime state into
  `~/.claude/settings.json` (e.g. the `wozcode` block), so `chezmoi apply`
  reverts those writes and `chezmoi diff` can show noise. Re-mirror the keys
  above when they matter; ignore the rest.
