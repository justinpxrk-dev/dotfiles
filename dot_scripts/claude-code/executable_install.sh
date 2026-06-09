#!/usr/bin/env bash
# Installs Claude Code via its native installer, which pulls releases straight from
# upstream — so new versions land immediately instead of waiting on Homebrew's
# `claude-code` cask to catch up. Replaces the former `claude-code@latest` cask.

set -euo pipefail

# The native installer lands the binary at ~/.local/bin/claude (latest channel by
# default, matching the former @latest cask). Bootstrap it only when absent — once
# installed it self-updates, so there is nothing to re-run on subsequent applies.
if [[ ! -x "$HOME/.local/bin/claude" ]]; then
	echo "==> Installing Claude Code via the native installer"
	curl -fsSL https://claude.ai/install.sh | bash
fi
