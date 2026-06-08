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
	Library/Themes/Catppuccin/delta \
	Library/Themes/Catppuccin/ghostty \
	Library/Themes/Catppuccin/spicetify \
	Library/Themes/tinted/tinted-shell

# Private submodules require SSH auth. Failure is silenced so a missing SSH
# key on non-authorized machines does not block the rest of the script.
# --recursive is omitted: these submodules are owner-maintained and have no
# nested submodules.
git submodule update --init --checkout --quiet -- \
	Library/Fonts/font-monolisa \
	Library/Fonts/lib/monolisa-nerdfont-patch ||
	true

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
	local name="font-monolisa" path="Library/Fonts/font-monolisa"
	local destination="$HOME/Library/Fonts"
	[[ -f "$path/fonts/MonoLisa-normal.ttf" ]] || return 0
	[[ -f "$path/fonts/MonoLisa-italic.ttf" ]] || return 0
	# Copy rather than symlink: macOS does not register fonts symlinked into
	# ~/Library/Fonts.
	local variant
	for variant in normal italic; do
		in_submodule "$name" "$path" "Installing MonoLisa-$variant.ttf" \
			cp "$REPO_ROOT/$path/fonts/MonoLisa-$variant.ttf" "$destination"
	done
}

install_monolisa_nerdfont_patch() {
	local name="monolisa-nerdfont-patch" path="Library/Fonts/lib/monolisa-nerdfont-patch"
	local fonts="$HOME/Library/Fonts"
	[[ -x "$path/patch-monolisa" ]] || return 0
	# patch-monolisa writes each font to <-o>/<source's parent dir>/. The copied
	# originals live in ~/Library/Fonts (parent dir "Fonts"), so -o ~/Library lands
	# the patched Nerd Fonts back in ~/Library/Fonts beside them.
	#
	# --name filename is required because both MonoLisa source files share one
	# internal name (they differ only by italic angle); without it font-patcher
	# names every variant "-Regular" and the italic clobbers the regular. Deriving
	# the style from the file name yields a proper Regular/Italic Nerd Font pair.
	local variant src
	for variant in normal italic; do
		src="$fonts/MonoLisa-$variant.ttf"
		[[ -f "$src" ]] || continue
		in_submodule "$name" "$path" "Patching ${src##*/}" \
			./patch-monolisa -f "$src" -c --name filename -o "$HOME/Library"
	done
	# Discard worktree changes in the submodule after patching so the superproject
	# does not report it as modified.
	in_submodule "$name" "$path" "Resetting" git restore .
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
