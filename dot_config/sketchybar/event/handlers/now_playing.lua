local sbar = require("sketchybar")

local item = require("constants.item")
local colorschemes = require("helpers.colorschemes")
local utils = require("helpers.utils")

local M = {}

M.PLAYING = false

local now_playing_track = "Not Playing"
local now_playing_artwork_path = "null"
local now_playing_inactive_artwork_path = "null"

function M.artwork_change_handler(env)
	local artwork_path = env.INFO.artwork_path
	local inactive_artwork_path = env.INFO.inactive_artwork_path

	now_playing_artwork_path = artwork_path
	now_playing_inactive_artwork_path = inactive_artwork_path

	local artwork_item_options = {
		background = {
			image = {
				string = M.PLAYING and now_playing_artwork_path or now_playing_inactive_artwork_path,
			},
		},
	}

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
end

--- Repaint the now-playing pill on a light/dark switch so it tracks the theme in step with the
--- rest of the bar: the track label and the artwork placeholder logo (only while the placeholder
--- is showing — i.e. no real track artwork), plus the surface `PILL` bracket, which re-takes the
--- inactive space-box fill + border like the Stats pills. Real album art is theme-independent, so
--- it is left untouched.
--- @return nil
function M.theme_change_handler()
	local artwork_item_options = colorschemes.get_now_playing_artwork_logo_color_options(M.PLAYING)
	local track_item_options = colorschemes.get_now_playing_track_color_options(M.PLAYING)

	if now_playing_artwork_path == "null" then
		sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	end
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
	sbar.set(item.NOW_PLAYING.PILL, { background = colorschemes.get_space_color_options(false).background })
end

function M.pause_handler()
	M.PLAYING = false

	-- Real album art when we have it; otherwise re-tint the placeholder logo to its dim
	-- (not-playing) variant, matching stop/theme so the placeholder always tracks play-state.
	local artwork_item_options = now_playing_inactive_artwork_path ~= "null"
			and {
				background = {
					image = {
						string = now_playing_inactive_artwork_path,
					},
				},
			}
		or colorschemes.get_now_playing_artwork_logo_color_options(M.PLAYING)
	local track_item_options = colorschemes.get_now_playing_track_color_options(M.PLAYING)

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.stop_handler()
	M.PLAYING = false
	now_playing_track = "Not Playing"
	now_playing_artwork_path = "null"
	now_playing_inactive_artwork_path = "null"

	local artwork_item_options = colorschemes.get_now_playing_artwork_logo_color_options(M.PLAYING)
	local track_item_options = utils.merge(colorschemes.get_now_playing_track_color_options(M.PLAYING), {
		click_script = "",
		label = { string = now_playing_track },
	})

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.unpause_handler()
	M.PLAYING = true

	-- Real album art when we have it; otherwise re-tint the placeholder logo to its bright
	-- (playing) variant, matching stop/theme so the placeholder always tracks play-state.
	local artwork_item_options = now_playing_artwork_path ~= "null"
			and {
				background = {
					image = {
						string = now_playing_artwork_path,
					},
				},
			}
		or colorschemes.get_now_playing_artwork_logo_color_options(M.PLAYING)
	local track_item_options = colorschemes.get_now_playing_track_color_options(M.PLAYING)

	sbar.set(item.NOW_PLAYING.ARTWORK, artwork_item_options)
	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

function M.track_change_handler(env)
	local playing = env.INFO.playing == "true" and true or false
	local artist = env.INFO.artist
	local bundle_identifier = env.INFO.bundle_identifier
	local title = env.INFO.title
	local track
	if artist ~= "null" and title ~= "null" then
		track = title .. " - " .. artist
	elseif title ~= "null" then
		track = title .. " - Unknown"
	elseif artist ~= "null" then
		track = "Unknown - " .. artist
	else
		track = "Unknown - Unknown"
	end

	M.PLAYING = playing
	now_playing_track = track

	local track_item_options = utils.merge(colorschemes.get_now_playing_track_color_options(M.PLAYING), {
		label = {
			string = now_playing_track,
		},
	}, bundle_identifier ~= "null" and {
		click_script = string.format("open -b %s", bundle_identifier),
	} or {})

	sbar.set(item.NOW_PLAYING.TRACK, track_item_options)
end

return M
