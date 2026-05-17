--- @class Asset
--- @field NOW_PLAYING table<AssetOption, AssetOptions>
--- @alias AssetOption "ARTWORK"
--- @alias AssetOptions table<AssetName, string>
--- @alias AssetName "DEFAULT_IMAGE_DARK_TRANSPARENT" | "DEFAULT_IMAGE_LIGHT_TRANSPARENT"

local asset_dir = os.getenv("HOME") .. "/.local/share/chezmoi/Assets/apple-music"

--- @type Asset
local M = {
	NOW_PLAYING = {
		ARTWORK = {
			DEFAULT_IMAGE_DARK_TRANSPARENT = asset_dir .. "/logo-dark.24x24.png",
			DEFAULT_IMAGE_LIGHT_TRANSPARENT = asset_dir .. "/logo-light.24x24.png",
			-- TODO: DEFAULT_IMAGE_DARK_TRANSPARENT and the LIGHT equivalent are 30% transparent. Create 100% opaque
			--		 versions for use as the default image when now_playing is playing but no artowrk data is available.
		},
	},
}

return M
