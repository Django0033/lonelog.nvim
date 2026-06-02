local M = {}

function M.telescope_pick(items, opts)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	pickers.new({}, {
		prompt_title = opts.title or "Select",
		finder = finders.new_table({
			results = items,
			entry_maker = function(item)
				return {
					value = item,
					display = opts.format_item(item),
					ordinal = opts.format_item(item),
				}
			end,
		}),
		sorter = conf.generic_sorter({}),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)
				local selection = action_state.get_selected_entry()
				if selection then
					opts.on_select(selection.value)
				end
			end)
			return true
		end,
	}):find()
end

-- Pick items using Telescope or native sidebar
---@param options table {items, format_items, on_select, title}
function M.pick(options)
	options = options or {}
	local items = options.items or {}
	local format_item = options.format_item or tostring
	local on_select = options.on_select or function() end

	if not require("lonelog.config").should_use_telescope() then
		require("lonelog.ui.sidebar").open(options.title or "Select", items, {
			format_item = format_item,
			on_select = on_select,
		})
		return
	end

	local ok, err = pcall(M.telescope_pick, items, {
		title = options.title or "Select",
		format_item = format_item,
		on_select = on_select,
	})
	if not ok then
		require("lonelog.ui.sidebar").open(options.title or "Select", items, {
			format_item = format_item,
			on_select = on_select,
		})
	end
end

return M
