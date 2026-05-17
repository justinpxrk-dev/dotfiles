#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$HOME/.local/share/chezmoi"
echo "==> Changing directory to $REPO_ROOT"
cd "$REPO_ROOT" || exit

echo "==> Syncing git submodules"
git submodule update --init --recursive --quiet

failed=()

in_submodule() {
	local name="$1" path="$2" label="$3"
	shift 3
	echo "==> $name ($path): $label"
	local output
	if ! output=$(cd "$path" && "$@" 2>&1); then
		printf '%s\n' "$output" >&2
		failed+=("$name ($label)")
		return 1
	fi
}

install_font_monolisa() {
	local name="font-monolisa" path="Fonts/font-monolisa"
	mkdir -p "$HOME/Library/Fonts/MonoLisa"
	in_submodule "$name" "$path" "Linking fonts" ln -sf "$REPO_ROOT/$path/fonts/MonoLisa-normal.ttf" "$HOME/Library/Fonts/MonoLisa/"
}

install_monolisa_nerdfont_patch() {
	local name="monolisa-nerdfont-patch" path="Fonts/lib/monolisa-nerdfont-patch"
	local source="$HOME/Library/Fonts/MonoLisa/MonoLisa-normal.ttf"
	local destination="$HOME/Library/Fonts/"
	mkdir -p "$destination"
	if [[ ! -f "$destination/MonoLisa/MonoLisaNerdFont-Regular.ttf" ]]; then
		in_submodule "$name" "$path" "Patching fonts" ./patch-monolisa -f "$source" -c -o "$destination"
	fi
}

install_sbarlua() {
	local name="SbarLua" path="dot_config/sketchybar/lib/SbarLua"
	in_submodule "$name" "$path" "Building" make install || return
	in_submodule "$name" "$path" "Resetting" git restore . || return
	in_submodule "$name" "$path" "Cleaning" git clean -fd
}

install_sketchybar_app_font() {
	local name="sketchybar-app-font" path="dot_config/sketchybar/lib/sketchybar-app-font"
	in_submodule "$name" "$path" "Installing dependencies" pnpm install || return
	in_submodule "$name" "$path" "Building" pnpm run build:install || return
	rm -f "$HOME/.config/sketchybar/helpers/icon_map.sh"
	in_submodule "$name" "$path" "Resetting" git restore . || return
	in_submodule "$name" "$path" "Cleaning" git clean -fd
}

install_font_monolisa
install_monolisa_nerdfont_patch
install_sbarlua
install_sketchybar_app_font

if ((${#failed[@]} > 0)); then
	echo "==> The following builds failed:" >&2
	printf '  > %s\n' "${failed[@]}" >&2
	exit 1
fi

echo "==> Done"
