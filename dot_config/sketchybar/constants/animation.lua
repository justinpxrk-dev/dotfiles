--- @class Animation
--- @field NOW_PLAYING table<NowPlayingAnimationOption, table<AnimationSetting, string | number>>
--- @alias NowPlayingAnimationOption "ACTIVATE" | "DEACTIVATE"
--- @alias AnimationSetting "LABEL_CURVE" | "LABEL_DURATION" | "LABEL_DURATION_SECONDS"

--- @type Animation
local M = {
	NOW_PLAYING = {
		ACTIVATE = {
			LABEL_CURVE = "circ",
			LABEL_DURATION = 18,
			LABEL_DURATION_SECONDS = 0.3,
		},
		DEACTIVATE = {
			LABEL_CURVE = "circ",
			LABEL_DURATION = 18,
			LABEL_DURATION_SECONDS = 0.3,
		},
	},
}

return M
