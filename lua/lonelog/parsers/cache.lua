-- NOTE: This file is currently only used by test files (test_cache.lua).
-- It is NOT required by any production source code in `/lua/`.
-- The refresh/get/invalidate pattern aggregates tags, scenes, and sessions
-- for efficient test-time assertions. Kept as test-only infrastructure.
local M = {}

local cache = {}

local ENTITY_TYPES = { N = true, L = true, PC = true, THREAD = true, F = true }
local PROGRESS_TYPES = { E = true, CLOCK = true, TRACK = true, TIMER = true }

function M.refresh(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local tags_mod = require("lonelog.parsers.tags")
	local scenes_mod = require("lonelog.parsers.scenes")
	local summary_mod = require("lonelog.commands.summary")

	local all_tags = tags_mod.parse_tags(bufnr)
	local all_scenes = scenes_mod.parse_scenes(bufnr)
	local all_sessions = summary_mod.parse_all_sessions(bufnr)

	local entities = {}
	for _, tag in ipairs(all_tags) do
		local t = tag.type
		if ENTITY_TYPES[t] then
			entities[t] = entities[t] or {}
			local name = tag.name
			local entry = entities[t][name]
			if entry then
				table.insert(entry.lines, tag.line)
				entry.last_seen = tag.line
				entry.mention_count = entry.mention_count + 1
			else
				entities[t][name] = {
					name = name,
					tags = tag.tags,
					lines = { tag.line },
					first_seen = tag.line,
					last_seen = tag.line,
					mention_count = 1,
				}
			end
		end
	end

	local progress = {}
	for _, tag in ipairs(all_tags) do
		local t = tag.type
		if PROGRESS_TYPES[t] then
			local current, max
			for _, s in ipairs(tag.tags) do
				local c, m = s:match("^(%d+)/(%d+)$")
				if c then
					current = tonumber(c)
					max = tonumber(m)
				else
					local c_only = tonumber(s:match("^(%d+)$"))
					if c_only then
						current = c_only
					end
				end
			end
			table.insert(progress, {
				type = t == "CLOCK" and "E" or t,
				name = tag.name,
				current = current,
				max = max,
				line = tag.line,
			})
		end
	end

	local function sort_by_name(t)
		local list = {}
		for _, entry in pairs(t or {}) do
			table.insert(list, entry)
		end
		table.sort(list, function(a, b)
			return a.name:lower() < b.name:lower()
		end)
		return list
	end

	local data = {
		npcs = sort_by_name(entities.N),
		locations = sort_by_name(entities.L),
		threads = sort_by_name(entities.THREAD),
		pcs = sort_by_name(entities.PC),
		foes = sort_by_name(entities.F),
		progress = progress,
		scenes = all_scenes,
		sessions = all_sessions,
	}

	cache[bufnr] = {
		changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
		data = data,
	}

	return data
end

function M.get(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local entry = cache[bufnr]
	local current_tick = vim.api.nvim_buf_get_changedtick(bufnr)
	if entry and current_tick == entry.changedtick then
		return entry.data
	end
	return M.refresh(bufnr)
end

function M.invalidate(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	cache[bufnr] = nil
end

return M
