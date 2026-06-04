local M = {}
local fmt = require("lonelog.commands.summary.format")
-- Parse all session headers from a buffer
---@param bufnr number|nil Buffer number (default: current)
---@return table[] Array of {number, date, start_line, end_line}
function M.parse_all_sessions(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local sessions = {}
	for i, line in ipairs(lines) do
		local n = line:match("^## Session (%d+)%s*$")
		if n then
			local num = tonumber(n)
			local date_line = i < #lines and lines[i + 1] or ""
			local date = date_line:match("^(%d%d%d%d%-%d%d%-%d%d)$") and date_line or nil
			table.insert(sessions, {
				number = num,
				date = date,
				start_line = i,
				end_line = nil,
			})
		end
	end
	for idx, s in ipairs(sessions) do
		local next_s = sessions[idx + 1]
		s.end_line = next_s and next_s.start_line or (#lines + 1)
	end
	return sessions
end

-- Get lines within a session's range (1-indexed)
local function session_lines(all_lines, session)
	local start = session.start_line
	local finish = session.end_line - 1
	local result = {}
	for i = start, finish do
		table.insert(result, all_lines[i])
	end
	return result
end

-- Count notation elements in a set of lines
local function count_notation(lines)
	local counts = {
		actions = 0,
		questions = 0,
		dice_lines = 0,
		arrows = 0,
		consequences = 0,
		table_rolls = 0,
		meta_notes = 0,
		narrative_blocks = 0,
		dialogues = 0,
		combat_blocks = 0,
	}
	for _, line in ipairs(lines) do
		if line:match("^@") then
			counts.actions = counts.actions + 1
		end
		if line:match("^%?") then
			counts.questions = counts.questions + 1
		end
		if line:match("^d:") then
			counts.dice_lines = counts.dice_lines + 1
		end
		if line:match(" %-> ") then
			counts.arrows = counts.arrows + 1
		end
		if line:match("^=> ") then
			counts.consequences = counts.consequences + 1
		end
		if line:match("^tbl:") then
			counts.table_rolls = counts.table_rolls + 1
		end
		if line:match("%(not[ea]:") then
			counts.meta_notes = counts.meta_notes + 1
		end
		if line:match("^\\%-%-%-") then
			counts.narrative_blocks = counts.narrative_blocks + 1
		end
		if line:match("^[NPC]+:.*\"") then
			counts.dialogues = counts.dialogues + 1
		end
		if line:match("%[COMBAT%]") then
			counts.combat_blocks = counts.combat_blocks + 1
		end
	end
	return counts
end

-- Parse dice result from a d: line like "d: 2d6+3[4, 2] = 10"
local function parse_dice_line(line)
	local notation, rolls_str, total_str = line:match("^d:%s*([^%[]+)%[([^%]]*)%]%s*=%s*(%d+)")
	if not notation then
		return nil
	end
	notation = vim.trim(notation)
	local total = tonumber(total_str)
	local rolls = {}
	for v in rolls_str:gmatch("(%d+)") do
		table.insert(rolls, tonumber(v))
	end
	return { notation = notation, rolls = rolls, total = total }
end

-- Build dice summary from d: lines within session
local function build_dice_summary(lines)
	local dice_data = { count = 0, sum = 0, breakdown = {} }
	for _, line in ipairs(lines) do
		local parsed = parse_dice_line(line)
		if parsed then
			dice_data.count = dice_data.count + 1
			dice_data.sum = dice_data.sum + parsed.total
			table.insert(dice_data.breakdown,
				parsed.notation .. " [" .. table.concat(parsed.rolls, ",") .. "] = " .. parsed.total)
		end
	end
	if dice_data.count > 0 then
		dice_data.average = math.floor((dice_data.sum / dice_data.count) * 10 + 0.5) / 10
	else
		dice_data.average = 0
	end
	return dice_data
end

-- Count progress elements (clocks, tracks, timers) and find completed ones
local function build_progress_summary(lines)
	local progress = { clocks = 0, tracks = 0, timers = 0, completed = {} }
	for _, line in ipairs(lines) do
		for tag_type, content in line:gmatch("%[(%w+):([^%]]+)%]") do
			local upper = tag_type:upper()
			if upper == "E" or upper == "CLOCK" then
				progress.clocks = progress.clocks + 1
				local curr_str, maxv_str = content:match("(%d+)/(%d+)$")
				if curr_str and maxv_str then
					local curr = tonumber(curr_str)
					local maxv = tonumber(maxv_str)
					if curr and maxv and curr >= maxv then
						local name = vim.trim(content:match("^(.-)%s+%d+") or content)
						table.insert(progress.completed, name)
					end
				end
			elseif upper == "TRACK" then
				progress.tracks = progress.tracks + 1
				local curr_str, maxv_str = content:match("(%d+)/(%d+)$")
				if curr_str and maxv_str then
					local curr = tonumber(curr_str)
					local maxv = tonumber(maxv_str)
					if curr and maxv and curr >= maxv then
						local name = vim.trim(content:match("^(.-)%s+%d+") or content)
						table.insert(progress.completed, name)
					end
				end
			elseif upper == "TIMER" then
				progress.timers = progress.timers + 1
			end
		end
	end
	return progress
end

-- Count words in non-notation lines
local function count_words(lines)
	local total = 0
	for _, line in ipairs(lines) do
		if not line:match("^[@?d:%->=>tbl:%%[\\---]") and not line:match("^(##|###|%- )") then
			local trimmed = vim.trim(line)
			if trimmed ~= "" then
				local wc = 0
				for _ in trimmed:gmatch("%S+") do
					wc = wc + 1
				end
				total = total + wc
			end
		end
	end
	return total
end

-- Filter cache progress items to a session's line range and convert to summary format.
---@param progress table Progress array from cache.get().progress
---@param session table Session object {start_line, end_line}
---@return table { clocks, tracks, timers, completed }
local function progress_from_cache(progress, session)
	local result = { clocks = 0, tracks = 0, timers = 0, completed = {} }
	for _, p in ipairs(progress) do
		if p.line >= session.start_line and p.line < session.end_line then
			if p.type == "E" or p.type == "CLOCK" then
				result.clocks = result.clocks + 1
			elseif p.type == "TRACK" then
				result.tracks = result.tracks + 1
			elseif p.type == "TIMER" then
				result.timers = result.timers + 1
			end
			if p.current and p.max and p.current >= p.max then
				table.insert(result.completed, p.name)
			end
		end
	end
	return result
end

-- Build a full summary for one session
---@param session table Session object {number, date, start_line, end_line}
---@param all_lines table All buffer lines (1-indexed)
---@param all_tags table All tags from parse_tags() / cache.get().tags
---@param all_scenes table All scenes from parse_scenes() / cache.get().scenes
---@param cached_progress? table Optional progress array from cache.get().progress
---@param roll_stats? table Optional roll statistics from cache.get().rolls
---@return table SessionSummary
function M.build_session_summary(session, all_lines, all_tags, all_scenes, cached_progress, roll_stats)
	local slines = session_lines(all_lines, session)
	local summary = {
		session = session,
		lines_count = #slines,
		words_count = count_words(slines),
		notation = count_notation(slines),
		dice = build_dice_summary(slines),
		progress = cached_progress and progress_from_cache(cached_progress, session) or build_progress_summary(slines),
		tags = {},
		scenes = {},
		tag_counts = {},
		scene_counts = {},
	}

	if roll_stats then
		summary.roll_stats = {
			by_type = roll_stats.by_type,
			total_rolls = roll_stats.total_rolls,
			oracle_results = roll_stats.oracle_results,
		}
	end

	-- Filter tags to this session's range
	for _, t in ipairs(all_tags) do
		if t.line >= session.start_line and t.line < session.end_line then
			table.insert(summary.tags, t)
		end
	end

	-- Build tag counts
	local tag_type_labels = require("lonelog.parsers.tags").TAG_TYPES
	for _, t in ipairs(summary.tags) do
		local key = t.type
		if not summary.tag_counts[key] then
			local tt = tag_type_labels[key]
			local label = (tt and tt.label) or key
			summary.tag_counts[key] = { label = label, count = 0 }
		end
		summary.tag_counts[key].count = summary.tag_counts[key].count + 1
	end

	-- Filter scenes to this session's range
	for _, s in ipairs(all_scenes) do
		if s.line >= session.start_line and s.line < session.end_line then
			table.insert(summary.scenes, s)
		end
	end

	-- Build scene counts
	local scene_types = require("lonelog.parsers.scenes").SCENE_TYPES
	for _, s in ipairs(summary.scenes) do
		local key = s.type
		if not summary.scene_counts[key] then
			local st = scene_types and scene_types[key]
			local label = (st and st.plural) or key
			summary.scene_counts[key] = { label = label, count = 0 }
		end
		summary.scene_counts[key].count = summary.scene_counts[key].count + 1
	end

	return summary
end

-- Format a session summary for display in floating window
---@param summary table SessionSummary
---@return string[]

-- Generate markdown export of a session summary
---@param summary table SessionSummary
---@return string
-- Build label items for the session picker (shared by show and export)
local function build_session_items(sessions)
	local items = {}
	for _, s in ipairs(sessions) do
		local label = "Session " .. s.number
		if s.date then
			label = label .. " (" .. s.date .. ")"
		end
		table.insert(items, { label = label, session = s })
	end
	return items
end

-- Get current buffer data needed for session operations
local function get_current_buffer_data()
	local d = require("lonelog.cache").get()
	return {
		lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false),
		tags = d.tags,
		scenes = d.scenes,
		progress = d.progress,
		rolls = d.rolls,
	}
end

-- Show session summary in floating window
function M.show_session_summary()
	local sessions = M.parse_all_sessions()
	if #sessions == 0 then
		vim.notify("lonelog: No sessions found in buffer", vim.log.levels.WARN)
		return
	end

	local data = get_current_buffer_data()

	local function display_summary(session)
		local summary = M.build_session_summary(session, data.lines, data.tags, data.scenes, data.progress, data.rolls)
		local lines = fmt.format_summary(summary)
		local float = require("lonelog.ui.floating")
		local export_text = fmt.export_summary(summary)

		float.open(lines, {
			title = "Session " .. session.number .. " Summary",
			insert_content = { export_text },
			target_bufnr = vim.api.nvim_get_current_buf(),
		})
	end

	if #sessions == 1 then
		display_summary(sessions[1])
		return
	end

	require("lonelog.ui").pick({
		title = "Select Session",
		items = build_session_items(sessions),
		format_item = function(i)
			return i.label
		end,
		on_select = function(i)
			display_summary(i.session)
		end,
	})
end

-- Export session summary to file
function M.export_session_summary()
	local sessions = M.parse_all_sessions()
	if #sessions == 0 then
		vim.notify("lonelog: No sessions found in buffer", vim.log.levels.WARN)
		return
	end

	local data = get_current_buffer_data()

	local function do_export(session)
		local summary = M.build_session_summary(session, data.lines, data.tags, data.scenes, data.progress, data.rolls)
		local export_text = fmt.export_summary(summary)
		local default_name = "session-" .. session.number .. "-summary.md"

		vim.ui.input({ prompt = "Export filename: ", default = default_name }, function(name)
			if not name or name == "" then
				name = default_name
			end
			local buf_dir = vim.fn.expand("%:p:h")
			local full_path = buf_dir .. "/" .. name
			local fd = io.open(full_path, "w")
			if fd then
				fd:write(export_text)
				fd:close()
				vim.notify("lonelog: Summary exported to " .. full_path, vim.log.levels.INFO)
			else
				vim.notify("lonelog: Could not write to " .. full_path, vim.log.levels.ERROR)
			end
		end)
	end

	if #sessions == 1 then
		do_export(sessions[1])
		return
	end

	require("lonelog.ui").pick({
		title = "Select Session to Export",
		items = build_session_items(sessions),
		format_item = function(i)
			return i.label
		end,
		on_select = function(i)
			do_export(i.session)
		end,
	})
end

M.format_summary = fmt.format_summary
M.export_summary = fmt.export_summary

return M
