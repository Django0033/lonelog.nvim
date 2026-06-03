local M = {}

function M.inv_delta()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
	if not line then
		return
	end

	local inv_tag = line:match("%[Inv:[^%]]+%]")
	if not inv_tag then
		vim.notify("lonelog: No [Inv:] tag found on this line", vim.log.levels.INFO)
		return
	end

	local inner = inv_tag:match("^%[Inv:(.*)%]$")
	if not inner then
		return
	end

	local parts = {}
	for p in inner:gmatch("[^|]+") do
		table.insert(parts, p)
	end
	if #parts == 0 then
		return
	end

	local last = parts[#parts]
	local qty = tonumber(last)
	if not qty then
		vim.notify("lonelog: No numeric quantity to adjust in inventory tag", vim.log.levels.INFO)
		return
	end

	vim.ui.input({ prompt = "Delta (e.g. -1, +2): " }, function(delta)
		if not delta or delta == "" then return end
		local cleaned = delta:gsub("%s+", "")
		local amount = tonumber(cleaned)
		if not amount or amount == 0 then return end
		local new_qty = qty + amount
		local new_last = new_qty <= 0 and "depleted" or tostring(new_qty)
		local left = inv_tag:match("^(.*|)")
		local s = left and (#left + 1) or 1
		local new_tag = inv_tag:sub(1, s - 1) .. new_last .. inv_tag:sub(s + #last)
		local new_line = line:gsub("%[Inv:[^%]]+%]", new_tag, 1)
		vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })
		vim.notify("lonelog: " .. inv_tag .. " -> " .. new_tag, vim.log.levels.INFO)
	end)
end

function M.item_state()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
	if not line then
		return
	end

	local inv_tag = line:match("%[Inv:[^%]]+%]")
	if not inv_tag then
		vim.notify("lonelog: No [Inv:] tag found on this line", vim.log.levels.INFO)
		return
	end

	local inner = inv_tag:match("^%[Inv:(.*)%]$")
	if not inner then
		return
	end

	local parts = {}
	for p in inner:gmatch("[^|]+") do
		table.insert(parts, p)
	end
	local item_name = parts[1]
	local props = {}
	for i = 2, #parts do
		table.insert(props, parts[i])
	end

	local prop_str = #props > 0 and table.concat(props, "|") or "(none)"
	vim.ui.input({ prompt = "Item state for " .. item_name .. " (current: " .. prop_str .. "): " }, function(input)
		if not input or input == "" then return end
		local new_props = {}
		for _, p in ipairs(props) do
			new_props[p] = true
		end
		for change in input:gmatch("%S+") do
			local add = change:match("^%+(.+)$")
			if add then new_props[add] = true end
			local remove = change:match("^%-(.+)$")
			if remove then new_props[remove] = nil end
		end
		local result = {}
		for p in pairs(new_props) do
			table.insert(result, p)
		end
		table.sort(result)
		local new_inner = #result > 0 and item_name .. "|" .. table.concat(result, "|") or item_name
		local new_tag = "[Inv:" .. new_inner .. "]"
		local new_line = line:gsub("%[Inv:[^%]]+%]", new_tag, 1)
		vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })
		vim.notify("lonelog: " .. inv_tag .. " -> " .. new_tag, vim.log.levels.INFO)
	end)
end

return M
