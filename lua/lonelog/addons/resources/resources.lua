local M = {}

function M.build_block(inv_items, wealth_items)
	local lines = { "--- RESOURCES ---" }
	for _, item in ipairs(inv_items or {}) do
		table.insert(lines, item)
	end
	for _, w in ipairs(wealth_items or {}) do
		table.insert(lines, w)
	end
	table.insert(lines, "---")
	return lines
end

function M.collect_items(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local inv_items = {}
	local wealth_items = {}
	for _, line in ipairs(lines) do
		local inv = line:match("%[Inv:[^%]]+%]")
		if inv then
			table.insert(inv_items, inv)
		end
		local wealth = line:match("%[Wealth:[^%]]+%]")
		if wealth then
			table.insert(wealth_items, wealth)
		end
	end
	return inv_items, wealth_items
end

function M.insert_block()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local inv_items, wealth_items = M.collect_items(bufnr)
	local block = M.build_block(inv_items, wealth_items)
	if #block <= 2 then
		vim.notify("lonelog: No inventory or wealth tags found", vim.log.levels.INFO)
		return
	end
	vim.api.nvim_buf_set_lines(bufnr, cursor[1], cursor[1], false, block)
end

function M.wealth_delta()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line = vim.api.nvim_buf_get_lines(bufnr, cursor[1] - 1, cursor[1], false)[1]
	if not line then
		return
	end

	local wealth_tag = line:match("%[Wealth:[^%]]+%]")
	if not wealth_tag then
		vim.notify("lonelog: No [Wealth:] tag found on this line", vim.log.levels.INFO)
		return
	end

	-- Parse currencies: [Wealth:Gold 40|Silver 50] -> {{name="Gold", value=40}, ...}
	local inner = wealth_tag:match("^%[Wealth:(.*)%]$")
	if not inner then
		return
	end
	local currencies = {}
	for pair in inner:gmatch("[^|]+") do
		local name, val = pair:match("(%a+)%s+(%d+)")
		if name and val then
			table.insert(currencies, { name = name, value = tonumber(val), raw = pair })
		end
	end

	if #currencies == 0 then
		vim.notify("lonelog: No currency values found in wealth tag", vim.log.levels.INFO)
		return
	end

	local function apply_delta(currency, amount)
		local new_value = currency.value + amount
		local new_pair = currency.name .. " " .. new_value
		local s = wealth_tag:find(currency.raw, 1, true)
		if not s then return end
		local new_tag = wealth_tag:sub(1, s - 1) .. new_pair .. wealth_tag:sub(s + #currency.raw)
		local new_line = line:gsub("%[Wealth:[^%]]+%]", new_tag, 1)
		vim.api.nvim_buf_set_lines(bufnr, cursor[1] - 1, cursor[1], false, { new_line })
		vim.notify("lonelog: " .. currency.raw .. " -> " .. new_value, vim.log.levels.INFO)
	end

	local function prompt_delta(currency)
		vim.ui.input({ prompt = "Delta for " .. currency.name .. " (e.g. +15, -8): " }, function(delta)
			if not delta or delta == "" then
				return
			end
			local cleaned = delta:gsub("%s+", "")
			local amount = tonumber(cleaned)
			if not amount or amount == 0 then
				return
			end
			apply_delta(currency, amount)
		end)
	end

	if #currencies == 1 then
		prompt_delta(currencies[1])
		return
	end

	local items = {}
	for _, c in ipairs(currencies) do
		table.insert(items, c.name .. " " .. c.value)
	end
	require("lonelog.ui").pick({
		title = "Select currency",
		items = items,
		format_item = function(item) return item end,
		on_select = function(choice)
			if not choice then return end
			for _, c in ipairs(currencies) do
				if c.name .. " " .. c.value == choice then
					prompt_delta(c)
					return
				end
			end
		end,
	})
end

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
		if not delta or delta == "" then
			return
		end
		local cleaned = delta:gsub("%s+", "")
		local amount = tonumber(cleaned)
		if not amount or amount == 0 then
			return
		end
		local new_qty = qty + amount
		local new_last
		if new_qty <= 0 then
			new_last = "depleted"
		else
			new_last = tostring(new_qty)
		end
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
		if not input or input == "" then
			return
		end
		local new_props = {}
		for _, p in ipairs(props) do
			new_props[p] = true
		end
		for change in input:gmatch("%S+") do
			local add = change:match("^%+(.+)$")
			if add then
				new_props[add] = true
			end
			local remove = change:match("^%-(.+)$")
			if remove then
				new_props[remove] = nil
			end
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

function M.slot_insert()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.ui.input({ prompt = "Slot number (e.g. 1, 5-10): " }, function(slot)
		if not slot or slot == "" then
			return
		end
		vim.ui.input({ prompt = "Contents (e.g. Sword, Torch×3, empty): " }, function(contents)
			if not contents or contents == "" then
				return
			end
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
				if n > max_slot then
					max_slot = n
				end
			end
		end
		local slot_range = line:match("%[Inv:Slot (%d+)%-%d+%|empty%]")
		if slot_range then
			local start_n = tonumber(slot_range)
			local end_n = line:match("%[Inv:Slot %d+%-(%d+)%|empty%]")
			if start_n and end_n then
				for i = start_n, tonumber(end_n) do
					occupied[i] = false
					if i > max_slot then
						max_slot = i
					end
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
		if occupied[i] == nil then
			free = free + 1
		elseif occupied[i] then
			used = used + 1
		end
	end

	vim.notify(string.format("lonelog: Slots %d/%d used, %d free", used, max_slot, free), vim.log.levels.INFO)
end

return M
