local M = {}

function M.show_roll_history()
	local bufnr = vim.api.nvim_get_current_buf()
	local dice_mod = require("lonelog.dice")
	local oracle_mod = require("lonelog.oracle")

	local dice_history = dice_mod.get_history(bufnr)
	local oracle_history = oracle_mod.get_history(bufnr)

	-- Take last 20 of each
	local max = 20
	local lines = {}

	if #dice_history > 0 then
		table.insert(lines, "── Dice Rolls ──")
		local start = math.max(1, #dice_history - max + 1)
		for i = start, #dice_history do
			local entry = dice_history[i]
			table.insert(lines, entry.result.display .. "  :" .. entry.line)
		end
		table.insert(lines, "")
	end

	if #oracle_history > 0 then
		table.insert(lines, "── Oracle Results ──")
		local start = math.max(1, #oracle_history - max + 1)
		for i = start, #oracle_history do
			local entry = oracle_history[i]
			local display = "[" .. entry.result.table_name .. "] " .. entry.result.display
			table.insert(lines, display .. "  :" .. entry.line)
		end
		table.insert(lines, "")
	end

	if #lines == 0 then
		table.insert(lines, "No roll history for this buffer.")
	end

	table.insert(lines, "q close  |  y copy")

	local ui = require("lonelog.ui.floating")
	ui.open(lines, { title = "Roll History" })
end

return M
