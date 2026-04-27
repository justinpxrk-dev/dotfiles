--- @class Utils
local M = {}

--- Recursively merges two tables, preserving values from `a` when `a` and `b` conflict.
--- - Same-type scalar conflicts: `a` wins.
--- - Same-type table conflicts: recurse.
--- - Type-mismatched conflicts (table vs scalar): `a` wins.
--- @param ... table
--- @return table merged
function M.merge(...)
	local result = {}
	local tables = { ... }
	for i = 1, #tables do
		local table = tables[i]
		for k, v in pairs(table) do
			if type(v) == "table" and type(result[k]) == "table" then
				result[k] = M.merge(result[k], v)
			elseif result[k] == nil then
				result[k] = v
			end
		end
	end
	return result
end

return M
