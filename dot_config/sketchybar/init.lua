local sbar = require("sketchybar")

-- Two sketchybar instances share this config tree, selected by environment. The
-- external bar's LaunchAgent launches the binary as `external` (so it registers
-- git.felix.external) and sets SKETCHYBAR_PROFILE=external; the default instance
-- (its own LaunchAgent, argv[0]=sketchybar) gets neither and falls through to the top
-- bar. See docs/architecture/sketchybar/architecture.md.
local profile = os.getenv("SKETCHYBAR_PROFILE") or "topbar"

-- SbarLua addresses git.felix.sketchybar by default; point it at the external
-- instance's port so this config's messages reach the matching daemon.
if profile == "external" then
	sbar.set_bar_name("external")
end

require("init." .. profile)
