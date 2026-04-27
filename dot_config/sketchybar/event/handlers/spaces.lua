--- @class SpacesManager
--- @field SPACES table<integer, table<integer, string>>
local M = {}

--- @type table<integer, table<integer, string>>
M.SPACES = {}

function M.spaces_change_handler() end

function M.theme_change_handler() end

return M
