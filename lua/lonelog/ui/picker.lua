local M = {}
local sidebar = require("lonelog.ui.sidebar")
local config = require("lonelog.config")

-- Pick items using sidebar or vim.ui.select
---@param options table {items, format_items, on_select, title}
function M.pick(options)
	options = options or {}
	local items = options.items or {}
	local format_item = options.format_item or tostring
	local on_select = options.on_select or function() end

	-- Use sidebar if Telescope is disabled
	if not require("lonelog.config").should_use_telescope() then
		require("lonelog.ui.sidebar").open(options.title or "Select", items, {
			format_item = format_item,
			on_select = on_select,
		})
		return
	end

	-- Use Telescope-compatible vim.ui.select
	vim.ui.select(items, { prompt = options.title or "Select", format_item = format_item }, function(choice)
		if choice then
			on_select(choice)
		end
	end)
end
return M
