# launch-agents.md

`me.justinpxrk.*` LaunchAgents are registered and reloaded by chezmoi **per-agent**, not by a glob. Each agent needs two tracked files that must stay paired:

1. **The plist** — `Library/LaunchAgents/me.justinpxrk.<name>.plist.tmpl` (chezmoi applies it to `~/Library/LaunchAgents/`).
2. **A reload trigger** — `.chezmoiscripts/run_onchange_after_reload-launch-agent-<name>.sh.tmpl`, whose hash comment is `{{ include "Library/LaunchAgents/me.justinpxrk.<name>.plist.tmpl" | sha256sum }}` and which runs `~/.scripts/macos/reload-launch-agent.sh me.justinpxrk.<name>`.

The trigger is what registers the agent on a fresh install and reloads it (`bootout` + `bootstrap`) whenever its plist changes — `run_onchange_` keys on the plist hash in that comment.

**Add an agent → add its trigger** (or chezmoi never loads it). **Remove an agent → delete both.** Nothing catches a missing or mismatched trigger; the symptom is an agent that silently never starts on a fresh install, or keeps running a stale definition after a plist edit (e.g. a renamed `ProgramArguments` path).
