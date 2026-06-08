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

brew bundle install --global
