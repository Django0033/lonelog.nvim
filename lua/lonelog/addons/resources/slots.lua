local M = {}

function M.slot_insert()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.ui.input({ prompt = "Slot number (e.g. 1, 5-10): " }, function(slot)
		if not slot or slot == "" then return end
		vim.ui.input({ prompt = "Contents (e.g. Sword, Torch×3, empty): " }, function(contents)
			if not contents or contents == "" then return end
			local tag = "[Inv:Slot " .. slot .. "|" .. contents .. "]"
			vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { tag })
		end)
	end)
end

function M.slot_summary()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local occupied = {}
	local max_slot = 0

	for _, line in ipairs(lines) do
		local slot_num = line:match("%[Inv:Slot (%d+)")
		if slot_num then
			local n = tonumber(slot_num)
			if n then
				occupied[n] = true
				if n > max_slot then max_slot = n end
			end
		end
		local slot_range = line:match("%[Inv:Slot (%d+)%-%d+%|empty%]")
		if slot_range then
			local start_n = tonumber(slot_range)
			local end_n = line:match("%[Inv:Slot %d+%-(%d+)%|empty%]")
			if start_n and end_n then
				for i = start_n, tonumber(end_n) do
					occupied[i] = false
					if i > max_slot then max_slot = i end
				end
			end
		end
	end

	if max_slot == 0 then
		vim.notify("lonelog: No inventory slots found", vim.log.levels.INFO)
		return
	end

	local used, free = 0, 0
	for i = 1, max_slot do
		if occupied[i] then
			used = used + 1
		else
			free = free + 1
		end
	end

	vim.notify(string.format("lonelog: Slots %d/%d used, %d free", used, max_slot, free), vim.log.levels.INFO)
end

return M
