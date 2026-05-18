#!/usr/bin/env bash

set -uo pipefail

REPO_ROOT="$HOME/.local/share/chezmoi"
echo "==> Changing directory to $REPO_ROOT"
cd "$REPO_ROOT" || exit

echo "==> Syncing git submodules"
# Public submodules use HTTPS; GIT_CONFIG_GLOBAL=/dev/null bypasses the global
# SSH rewrite rule so they clone via HTTPS directly without SSH auth.
GIT_CONFIG_GLOBAL=/dev/null git submodule update --init --recursive --quiet -- \
	dot_config/sketchybar/lib/SbarLua \
	dot_config/sketchybar/lib/sketchybar-app-font \
	Themes/lib/tinted-terminal \
	Themes/lib/tinted-vscode \
	Themes/lib/tinted-shell

# Private submodules require SSH auth. Failure is silenced so a missing SSH
# key on non-authorized machines does not block the rest of the script.
# --recursive is omitted: these submodules are owner-maintained and have no
# nested submodules.
git submodule update --init --checkout --quiet -- \
	Fonts/font-monolisa \
	Fonts/lib/monolisa-nerdfont-patch || true

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
	[[ -f "$path/fonts/MonoLisa-normal.ttf" ]] || return 0
	mkdir -p "$HOME/Library/Fonts/MonoLisa"
	in_submodule "$name" "$path" "Linking fonts" ln -sf "$REPO_ROOT/$path/fonts/MonoLisa-normal.ttf" "$HOME/Library/Fonts/MonoLisa/"
}

install_monolisa_nerdfont_patch() {
	local name="monolisa-nerdfont-patch" path="Fonts/lib/monolisa-nerdfont-patch"
	local source="$HOME/Library/Fonts/MonoLisa/MonoLisa-normal.ttf"
	local destination="$HOME/Library/Fonts/"
	[[ -f "$path/patch-monolisa" ]] || return 0
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
	# pnpm 11+ refuses to run dependency build scripts unless they are
	# explicitly approved via `allowBuilds` in pnpm-workspace.yaml. Upstream
	# doesn't ship one, so write it locally; `git clean -fd` below removes it.
	printf 'allowBuilds:\n  ttf2woff2: true\n' >"$path/pnpm-workspace.yaml"
	in_submodule "$name" "$path" "Installing dependencies" mise exec -- pnpm install || return
	in_submodule "$name" "$path" "Building" mise exec -- pnpm run build:install || return
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
