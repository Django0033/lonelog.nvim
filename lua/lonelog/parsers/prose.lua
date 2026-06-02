local M = {}

function M.parse_prose(lines)
	local tokenizer = require("lonelog.parsers.tokenizer")

	local result = {
		meta_notes = {},
		dialogues = {},
		narrative_blocks = {},
	}

	local in_narrative = false
	local narrative_start = nil

	for line_num, line in ipairs(lines) do
		local tok = tokenizer.tokenize(line)
		if not tok then
			goto continue
		end

		local trimmed = line:match("^%s*(.-)%s*$")

		-- Narrative block boundaries
		if tok.type == "narrative" then
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
		if tok.type == "meta" then
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

	return result
end

return M
