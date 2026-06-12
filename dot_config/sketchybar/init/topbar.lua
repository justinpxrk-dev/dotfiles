local sbar = require("sketchybar")

local option = require("constants.option")

-- Built-in top bar (default instance), mirroring the macOS menu bar. Items are a
-- TODO — for now this is an empty, menu-bar-styled placeholder.
sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.TOP)
