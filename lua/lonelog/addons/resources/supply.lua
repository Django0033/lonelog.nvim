local M = {}

local DEGRADE_CHAIN = { d8 = "d6", d6 = "d4", d4 = "exhausted" }

function M.roll_supply()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
	if not line then
		return
	end

	local pc_tag = line:match("%[PC:[^%]]+%]")
	if not pc_tag then
		vim.notify("lonelog: No [PC:] tag found on this line", vim.log.levels.INFO)
		return
	end

	local supply = pc_tag:match("Supply (d%d+)")
	if not supply then
		vim.notify("lonelog: No Supply die found in PC tag", vim.log.levels.INFO)
		return
	end

	local sides = tonumber(supply:match("%d+"))
	if not sides then
		return
	end

	local dice = require("lonelog.dice")
	local result, err = dice.roll("1d" .. sides)
	if not result then
		vim.notify("lonelog: " .. tostring(err), vim.log.levels.ERROR)
		return
	end

	local degraded = false
	local new_supply
	if result.total <= 2 then
		degraded = true
		new_supply = DEGRADE_CHAIN[supply]
	end

	local new_tag
	if new_supply then
		if new_supply == "exhausted" then
			new_tag = pc_tag:gsub("Supply " .. supply, "Supply exhausted")
		else
			new_tag = pc_tag:gsub("Supply " .. supply, "Supply " .. new_supply)
		end
	else
		new_tag = pc_tag
	end

	local new_line = line:gsub("%[PC:[^%]]+%]", new_tag, 1)
	vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })

	local msg = string.format("Supply %s = %d", supply, result.total)
	if degraded then
		if new_supply == "exhausted" then
			msg = msg .. " -> exhausted"
		else
			msg = msg .. " -> " .. new_supply
		end
	end
	vim.notify("lonelog: " .. msg, vim.log.levels.INFO)
end

return M
