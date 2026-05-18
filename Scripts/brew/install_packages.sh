#!/usr/bin/env bash
# Installs Homebrew if not present, then installs all packages from ~/.Brewfile.

set -euo pipefail

if ! command -v brew &>/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew bundle install --global
