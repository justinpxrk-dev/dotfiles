--- @class AppIcons
local M = {}

-- icon_map.lua is generated at install time by sketchybar-app-font's
-- `pnpm run build:install` (see dot_scripts/git/install-submodules.sh), not tracked in
-- this repo. Load it by absolute path with `dofile` rather than `require`: it is not a
-- resolvable source module, so a `require` would raise a lua-language-server diagnostic.
local home = assert(os.getenv("HOME"), "HOME must be set")

-- Load defensively: the generated map is absent on a fresh checkout or after a failed
-- `pnpm run build:install`. A raw `dofile` would raise at require time and abort the *entire* bar
-- (this module sits on the require chain from init/topbar.lua), so fall back to an empty map —
-- every app then resolves to `:default:` and the bar still starts.
local ok, loaded = pcall(dofile, home .. "/.config/sketchybar/helpers/icon_map.lua")
--- @type table<string, string> yabai `.app` name -> ":glyph:" ligature
local icon_map = (ok and type(loaded) == "table") and loaded or {}

--- Look up the sketchybar-app-font ligature for an app. The generated Lua map has no
--- default key (unlike the old shell map), so unmapped apps fall back to `:default:`.
--- yabai's `.app` string matches the map keys directly (no normalization).
--- @param app string yabai window `.app` name
--- @return string ":glyph:" ligature, or ":default:" when unmapped
function M.lookup(app)
	return icon_map[app] or ":default:"
end

return M
