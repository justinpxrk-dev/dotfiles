#!/usr/bin/env bash
# Installs Homebrew if not present, then installs all packages from ~/.Brewfile.

set -euo pipefail

if ! command -v brew &>/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Trust the third-party formula taps this setup installs from so they pass
# HOMEBREW_REQUIRE_TAP_TRUST. Older Homebrew (e.g. the CI runner image) has no
# `brew trust` subcommand and ignores the env var entirely, so skip it there.
if brew trust --help &>/dev/null; then
	brew trust --formula asmvik/formulae/skhd
	brew trust --formula asmvik/formulae/yabai
	brew trust --formula cormacrelf/tap/dark-notify
	brew trust --formula FelixKratz/formulae/borders
	brew trust --formula FelixKratz/formulae/sketchybar
	brew trust --formula spicetify/tap/spicetify-cli
	brew trust --formula tinted-theming/tinted/tinted-builder-rust
fi

# Mac App Store apps can't be installed in CI: the runner isn't signed in to the
# App Store, and `mas signin` is dead on macOS 10.13+ so there's no headless way
# to authenticate — `mas install` would hang/fail. HOMEBREW_BUNDLE_MAS_SKIP skips
# by app ID (not name) and has no "skip all" value, so collect every id from the
# Brewfile and skip them; brew and cask entries still install.
if [ -n "${CI:-}" ]; then
	mas_ids="$(grep -E '^[[:space:]]*mas ' "$HOME/.Brewfile" | grep -oE 'id:[[:space:]]*[0-9]+' | grep -oE '[0-9]+' | tr '\n' ' ' || true)"
	export HOMEBREW_BUNDLE_MAS_SKIP="$mas_ids"
fi

brew bundle install --global
