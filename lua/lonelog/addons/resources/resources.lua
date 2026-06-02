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
	local currencies = {}
	for pair in wealth_tag:gmatch("[^|]+") do
		local clean = pair:gsub("[%[%]]", "")
		local name, val = clean:match("(%a+)%s+(%d+)")
		if name and val then
			table.insert(currencies, { name = name, value = tonumber(val), raw = clean })
		end
	end

	if #currencies == 0 then
		vim.notify("lonelog: No currency values found in wealth tag", vim.log.levels.INFO)
		return
	end

	local function apply_delta(currency, amount)
		local new_value = currency.value + amount
		local new_pair = currency.name .. " " .. new_value
		local new_tag = wealth_tag:gsub("%" .. currency.raw, new_pair, 1)
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

return M
