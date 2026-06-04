local M = {}

local function classify(trimmed)
	-- Note: `-` is a magic character in Lua patterns (lazy repetition operator).
	-- Must escape literal dashes with `%-`.
	if trimmed:match("^\\%-%-%-") then
		return "narrative" -- \---
	elseif trimmed:match("^%-%-%-\\") then
		return "narrative" -- ---\
	elseif trimmed:match("^%-%-%-$") then
		return "narrative" -- exactly ---
	elseif trimmed:match("^%(") then
		return "meta"
	end
	return "text"
end

--- Parse session lines into structured prose elements.
---@param lines string[] Array of lines (1-indexed, as from nvim_buf_get_lines)
---@return table { meta_notes = table[], dialogues = table[], narrative_blocks = table[] }
function M.parse_prose(lines)
	local result = {
		meta_notes = {},
		dialogues = {},
		narrative_blocks = {},
	}

	local in_narrative = false
	local narrative_start = nil

	for line_num, line in ipairs(lines) do
		local trimmed = line:match("^%s*(.-)%s*$")
		if not trimmed or trimmed == "" then
			goto continue
		end

		local lt = classify(trimmed)

		-- Narrative block boundaries
		if lt == "narrative" then
			if trimmed == "\\---" then
				if not in_narrative then
					in_narrative = true
					narrative_start = line_num
				end
			elseif trimmed == "---\\" then
				if in_narrative and narrative_start then
					table.insert(result.narrative_blocks, {
						start_line = narrative_start,
						end_line = line_num,
					})
					in_narrative = false
					narrative_start = nil
				end
			elseif trimmed == "---" then
				if in_narrative then
					table.insert(result.narrative_blocks, {
						start_line = narrative_start,
						end_line = line_num,
					})
					in_narrative = false
					narrative_start = nil
				else
					in_narrative = true
					narrative_start = line_num
				end
			end
			goto continue
		end

		-- Meta notes: (note: ...)
		if lt == "meta" then
			local content = trimmed:match("^%((.-)%)$")
			if content then
				table.insert(result.meta_notes, {
					content = content,
					line = line_num,
				})
			end
			goto continue
		end

		-- Dialogue: Name: "text" or Context (Name): "text"
		local speaker, text = trimmed:match("^([%w%s%(%)]+):%s*\"(.+)\"$")
		if speaker then
			speaker = speaker:match("^%s*(.-)%s*$")
			table.insert(result.dialogues, {
				speaker = speaker,
				text = text,
				line = line_num,
			})
			goto continue
		end

		::continue::
	end

	-- Close any unclosed narrative block at end of input
	if in_narrative and narrative_start then
		table.insert(result.narrative_blocks, {
			start_line = narrative_start,
			end_line = #lines,
		})
	end

	return result
end

return M
