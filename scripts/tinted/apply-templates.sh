#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$HOME/.local/share/chezmoi"
THEME="${1:?Usage: apply-templates.sh <theme-name>}"

if [[ ! -d "$REPO_ROOT/Library/Themes/$THEME" ]]; then
	echo "error: theme directory '$REPO_ROOT/Library/Themes/$THEME' does not exist" >&2
	exit 1
fi

tinted-builder-rust build "$REPO_ROOT/Library/Themes/tinted/tinted-shell" \
	--schemes-dir "$REPO_ROOT/Library/Themes/$THEME"
cp "$REPO_ROOT/Library/Themes/tinted/tinted-shell/profile_helper.sh" \
	"$REPO_ROOT/dot_config/zsh/themes/profile_helper.sh"
mv "$REPO_ROOT/Library/Themes/tinted/tinted-shell/scripts/"*.sh \
	"$REPO_ROOT/dot_config/zsh/themes/scripts/"
rm -rf "$REPO_ROOT/Library/Themes/tinted/tinted-shell/scripts"
