--- @class Asset
--- @field NOW_PLAYING table<AssetOption, AssetOptions>
--- @alias AssetOption "ARTWORK"
--- @alias AssetOptions table<AssetName, string>
--- @alias AssetName "DARK_ACTIVE" | "DARK_INACTIVE" | "LIGHT_ACTIVE" | "LIGHT_INACTIVE"

local asset_dir = os.getenv("HOME") .. "/.local/share/chezmoi/assets/apple-music"

--- @type Asset
local M = {
	NOW_PLAYING = {
		-- Play-state-tinted placeholder logos, shown when a track has no real artwork. The white
		-- Apple Music logo is recoloured to a palette foreground role — the bright `text` (active /
		-- playing) or dim `overlay1` (inactive / not playing) — with the music note left as a fully
		-- transparent cutout (the pill surface shows through it). sketchybar cannot tint an image at
		-- runtime, so each state+palette is a pre-baked PNG (regenerate from the 800x800 masters with
		-- `magick MASTER -fill HEX -colorize 100 -channel A -threshold 60% +channel -filter Lanczos
		-- -resize 20x20 OUT` if the palette changes; see docs/ops/upgrade-hazards.md). Both pairs are
		-- used now that the bar tracks the system theme — the DARK (Mocha) pair in dark mode, the
		-- LIGHT (Latte) pair in light mode, selected by the theme-aware colour helper.
		ARTWORK = {
			DARK_ACTIVE = asset_dir .. "/logo-dark.active.20x20.png",
			DARK_INACTIVE = asset_dir .. "/logo-dark.inactive.20x20.png",
			LIGHT_ACTIVE = asset_dir .. "/logo-light.active.20x20.png",
			LIGHT_INACTIVE = asset_dir .. "/logo-light.inactive.20x20.png",
		},
	},
}

return M
