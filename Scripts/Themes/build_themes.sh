#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$HOME/.local/share/chezmoi"
THEME="${1:?Usage: build_themes.sh <theme-name>}"

if [[ ! -d "$REPO_ROOT/Themes/$THEME" ]]; then
	echo "error: theme directory '$REPO_ROOT/Themes/$THEME' does not exist" >&2
	exit 1
fi

tinted-builder-rust build "$REPO_ROOT/Themes/lib/tinted-shell" \
	--schemes-dir "$REPO_ROOT/Themes/$THEME"
cp "$REPO_ROOT/Themes/lib/tinted-shell/profile_helper.sh" \
	"$REPO_ROOT/dot_config/zsh/themes/profile_helper.sh"
mv "$REPO_ROOT/Themes/lib/tinted-shell/scripts/"*.sh \
	"$REPO_ROOT/dot_config/zsh/themes/scripts/"
rm -rf "$REPO_ROOT/Themes/lib/tinted-shell/scripts"

tinted-builder-rust build "$REPO_ROOT/Themes/lib/tinted-terminal" \
	--schemes-dir "$REPO_ROOT/Themes/$THEME"
mv "$REPO_ROOT/Themes/lib/tinted-terminal/themes/ghostty/"* \
	"$REPO_ROOT/dot_config/ghostty/themes/"
rm -rf "$REPO_ROOT/Themes/lib/tinted-terminal/themes"

tinted-builder-rust build "$REPO_ROOT/Themes/lib/tinted-vscode" \
	--schemes-dir "$REPO_ROOT/Themes/$THEME"
(cd "$REPO_ROOT/Themes/lib/tinted-vscode" &&
	pnpm update:packagejson:themes &&
	pnpm dlx @vscode/vsce package --no-dependencies --out tinted-vscode.vsix)
VSIX="$REPO_ROOT/Themes/lib/tinted-vscode/tinted-vscode.vsix"
code --install-extension "$VSIX"
python -c "
import json
path = '$HOME/.vscode/extensions/extensions.json'
with open(path) as f:
    data = json.load(f)
for e in data:
    if e['identifier']['id'] == 'tintedtheming.base16-tinted-themes':
        e.setdefault('metadata', {})['isApplicationScoped'] = True
with open(path, 'w') as f:
    json.dump(data, f)
"
rm -rf \
	"$REPO_ROOT/Themes/lib/tinted-vscode/themes" \
	"$REPO_ROOT/Themes/lib/tinted-vscode/node_modules"
rm "$VSIX"
