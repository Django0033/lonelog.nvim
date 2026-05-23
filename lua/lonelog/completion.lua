local M = {}

-- Cache per buffer: maps bufnr -> { changedtick, names }
-- names is a table of type_key -> name[] (e.g. N -> { "Jonah", "Alice" })
local cache = {}

function M.refresh_completions(bufnr)
	bufnr = bufnr or 0
	local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
	local entry = cache[bufnr]
	if entry and changedtick == entry.changedtick then
		return
	end

	local tags_mod = require("lonelog.parsers.tags")
	local tags = tags_mod.parse_tags(bufnr)

	local groups = {}
	for _, tag in ipairs(tags) do
		if tag.name and tag.name ~= "" then
			groups[tag.type] = groups[tag.type] or {}
			groups[tag.type][tag.name] = true
		end
	end

	local fresh = {}
	for type_key, name_set in pairs(groups) do
		local list = {}
		for name in pairs(name_set) do
			table.insert(list, name)
		end
		table.sort(list)
		fresh[type_key] = list
	end
	cache[bufnr] = { changedtick = changedtick, names = fresh }
end

function M.complete_tag()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]
	local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
	if not line then
		return
	end

	local before_cursor = line:sub(1, col + 1)

	local s, e, hash, type_key, query = before_cursor:find("%[(#?)([%w]+):([^%]|]*)$")
	if not s then
		return
	end

	local type_upper = type_key:upper()
	local tags_mod = require("lonelog.parsers.tags")
	if not tags_mod.TAG_TYPES[type_upper] then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	M.refresh_completions(bufnr)

	local entry = cache[bufnr]
	if not entry then
		return
	end
	local all = entry.names[type_upper] or {}
	if #all == 0 then
		return
	end

	local q = query:lower()
	local matches = {}
	for _, name in ipairs(all) do
		if q == "" or name:lower():find(q, 1, true) then
			table.insert(matches, name)
		end
	end

	if #matches == 0 then
		return
	end

	table.sort(matches, function(a, b)
		local al, bl = a:lower(), b:lower()
		if al == q and bl ~= q then
			return true
		end
		if al ~= q and bl == q then
			return false
		end
		if al:sub(1, #q) == q and bl:sub(1, #q) ~= q then
			return true
		end
		if al:sub(1, #q) ~= q and bl:sub(1, #q) == q then
			return false
		end
		return al < bl
	end)

	local items = {}
	for _, name in ipairs(matches) do
		table.insert(items, { word = name })
	end

	-- startcol: 1-indexed position of first char to replace (right after :)
	-- s = position of [, hash = # or "", type_key = N/L/PC/...
	-- s + #hash + #type_key = position of :
	-- s + #hash + #type_key + 2 = position after : and its following char
	local startcol = s + #hash + #type_key + 2
	vim.fn.complete(startcol, items)
end

function M.try_complete()
	if vim.fn.pumvisible() > 0 then
		return
	end
	local ok, err = pcall(M.complete_tag)
	if not ok then
		vim.notify("lonelog: Completion error: " .. tostring(err), vim.log.levels.ERROR)
	end
end

return M
