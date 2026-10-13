--- Load the chosen bar profile for the named SketchyBar instance.
local sbar = require("sketchybar")

-- SketchyBar exports its process name to child scripts so clients can address
-- that instance independently of the chosen configuration style.
local bar_name = os.getenv("BAR_NAME") or "sketchybar"
sbar.set_bar_name(bar_name)

-- The LaunchAgent chooses the profile; default to menubar when run manually.
local profile = os.getenv("SKETCHYBAR_PROFILE") or "menubar"
require("init." .. profile)
