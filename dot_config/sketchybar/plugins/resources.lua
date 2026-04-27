local sbar = require("sketchybar")

local item = require("constants.item")
local option = require("constants.option")

sbar.add("item", item.RESOURCES.EVENT_LISTENER, option.EVENT_LISTENER.OPTIONS)
sbar.add("graph", item.RESOURCES.CPU_GRAPH, 40, option.RESOURCES.CPU_GRAPH)
sbar.add("item", item.RESOURCES.CPU, option.RESOURCES.CPU)
