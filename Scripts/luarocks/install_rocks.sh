#!/usr/bin/env bash
# Installs LuaRocks dependencies into the user tree (~/.luarocks). Homebrew Bundle
# has no luarocks entry type, so rocks are installed here instead of the Brewfile.
# sketchybar loads the catppuccin rock from ~/.luarocks/share/lua/<ver>/; the Lua
# version is coupled to Homebrew's lua and SbarLua — see docs/ops/upgrade-hazards.md.

set -euo pipefail

# Ensure Homebrew (hence luarocks/lua) is on PATH even in a bare bootstrap shell,
# using brew's absolute path so it works before the shell profile is set up.
if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

luarocks install --local catppuccin
