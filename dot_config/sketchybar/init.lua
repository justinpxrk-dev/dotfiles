local sbar = require("sketchybar")

local option = require("constants.option")

-- Initialize bar and default options
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.OPTIONS)

-- Add theme plugin
require("plugins.theme")
-- Add left bar plugins
require("plugins.now_playing")
-- Add center bar plugins
require("plugins.spaces")
-- Add right bar plugins
require("plugins.resources")
