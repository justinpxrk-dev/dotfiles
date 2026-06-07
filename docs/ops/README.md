# ops

Operational notes for keeping this setup running over time: the couplings, manual steps, and gotchas that no test or lint enforces and that need a human in the loop — typically surfacing on upgrade or fresh install.

## Contents

- [`claude-plugins.md`](claude-plugins.md) — what's tracked vs. machine-local for Claude Code plugins, and the manual install steps for WOZCODE.
- [`launch-agents.md`](launch-agents.md) — the per-agent plist ↔ reload-trigger pairing chezmoi needs to register and reload `me.justinpxrk.*` LaunchAgents.
- [`manual-apps.md`](manual-apps.md) — GUI apps installed by hand (not Homebrew or the App Store) that must be re-downloaded on a fresh machine.
- [`upgrade-hazards.md`](upgrade-hazards.md) — things that break silently when an upstream tool is upgraded.
