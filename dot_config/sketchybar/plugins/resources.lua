-- Build the Stats resource widgets into the top bar's right region. The construction — the
-- mirrored Stats `alias` items, the pixel-tuned spacing, and the pill/divider chrome — lives in
-- `event/handlers/resources.lua` (`M.build`), beside the theme repaint that shares its
-- `PILLS`/`DIVIDERS`, so this plugin is just the entry point that runs the build at the right
-- point in the init sequence (see `init/topbar.lua`).
require("event.handlers.resources").build()
