--- Configure a panel for the display's spaces and active space.
local sbar = require("sketchybar")

local option = require("constants.option")

sbar.default(option.DEFAULT.OPTIONS)
sbar.bar(option.BAR.BOTTOM)

require("plugins.spaces")
