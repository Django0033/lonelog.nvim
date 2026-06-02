-- NOTE: This file is only used by parsers/prose.lua (which is itself unused
-- in production) and test files. Not required by any production source code.
local M = {}

local function dice_tokens(text)
	local tokens = {}
	local s = 1
	local prefix_end = text:match("^%s*d:")
	if prefix_end then
		table.insert(tokens, { type = "dice_prefix", text = "d:", start = s, finish = s + 1 })
		s = s + 2
	end
	local _, arrow_end = text:find("->", s)
	if arrow_end then
		local notation = text:sub(s, arrow_end - 3)
		if notation and notation ~= "" then
			table.insert(tokens, { type = "notation", text = notation, start = s, finish = arrow_end - 3 })
		end
		table.insert(tokens, { type = "result_arrow", text = "->", start = arrow_end - 1, finish = arrow_end })
		local result = text:sub(arrow_end + 1)
		if result and result ~= "" then
			table.insert(tokens, { type = "result_value", text = result, start = arrow_end + 1, finish = #text })
		end
		return tokens
	end
	local notation = text:sub(s)
	if notation and notation ~= "" then
		table.insert(tokens, { type = "notation", text = notation, start = s, finish = #text })
	end
	return tokens
end

local function line_type(line)
	if line:match("^%[COMBAT%]$") or line:match("^%[/COMBAT%]$") then
		return "combat_block"
	end
	if line:match("^## Session ") or line:match("^===") then
		return "header"
	end
	if line:match("^###%s+S") then
		return "scene"
	end
	if line:match("^---%s*$") then
		return "narrative"
	end
	if line:byte(1) == 92 then
		local rest = line:sub(2)
		if rest:match("^---") then
			return "narrative"
		end
	end
	if line:byte(1) == 45 and line:byte(2) == 45 and line:byte(3) == 45 and line:byte(4) == 92 then
		return "narrative"
	end
	if line:match("^@") then
		return "action"
	end
	if line:match("^%?") then
		return "question"
	end
	if line:match("^=>") then
		return "consequence"
	end
	if line:match("^gen:") then
		return "gen"
	end
	if line:match("^tbl:") then
		return "tbl"
	end
	if line:match("^d:") then
		return "dice"
	end
	if line:match("^%(") then
		return "meta"
	end
	return "text"
end

function M.tokenize(line)
	if not line or line == "" then
		return nil
	end
	if not line:match("%S") then
		return nil
	end

	local trimmed = line:match("^%s*(.-)%s*$")
	local indent = line:match("^(%s*)")

	local lt = line_type(trimmed)
	if lt == "dice" then
		return {
			type = "dice",
			text = line,
			indent = indent,
			tokens = dice_tokens(trimmed),
		}
	end

	local tokens = {}
	if lt == "action" then
		tokens[1] = { type = "symbol", text = "@", start = #indent + 1, finish = #indent + 1 }
		local rest = line:sub(#indent + 3)
		if rest and rest ~= "" then
			tokens[2] = { type = "text", text = rest, start = #indent + 3, finish = #line }
		end
	elseif lt == "question" then
		tokens[1] = { type = "symbol", text = "?", start = #indent + 1, finish = #indent + 1 }
		local rest = line:sub(#indent + 3)
		if rest and rest ~= "" then
			tokens[2] = { type = "text", text = rest, start = #indent + 3, finish = #line }
		end
	elseif lt == "consequence" then
		tokens[1] = { type = "symbol", text = "=>", start = #indent + 1, finish = #indent + 2 }
		local rest = line:sub(#indent + 4)
		if rest and rest ~= "" then
			tokens[2] = { type = "text", text = rest, start = #indent + 4, finish = #line }
		end
	elseif lt == "header" then
		tokens[1] = { type = "header_text", text = trimmed, start = #indent + 1, finish = #line }
	elseif lt == "scene" then
		tokens[1] = { type = "scene_id", text = trimmed:match("###%s+(%S+)"), start = #indent + 1, finish = #indent + 5 }
		local ctx = trimmed:match("%*(.-)%*")
		if ctx then
			local ctx_start = #indent + trimmed:find("%*")
			tokens[2] = { type = "context", text = ctx, start = ctx_start, finish = ctx_start + #ctx - 1 }
		end
	elseif lt == "narrative" then
		tokens[1] = { type = "narrative_marker", text = trimmed, start = #indent + 1, finish = #line }
	elseif lt == "gen" then
		tokens[1] = { type = "gen_prefix", text = "gen:", start = #indent + 1, finish = #indent + 4 }
		local name = trimmed:match("^gen:%s*(.+)")
		if name then
			tokens[2] = { type = "gen_name", text = name, start = #indent + 6, finish = #line }
		end
	elseif lt == "tbl" then
		tokens[1] = { type = "tbl_prefix", text = "tbl:", start = #indent + 1, finish = #indent + 4 }
		local name = trimmed:match("^tbl:%s*(.+)")
		if name then
			tokens[2] = { type = "tbl_name", text = name, start = #indent + 6, finish = #line }
		end
	elseif lt == "meta" then
		tokens[1] = { type = "meta_prefix", text = "(", start = #indent + 1, finish = #indent + 1 }
		local content = trimmed:match("^%((.-)%)")
		if content then
			tokens[2] = { type = "meta_content", text = content, start = #indent + 2, finish = #indent + 1 + #content }
		end
	elseif lt == "combat_block" then
		tokens[1] = { type = "combat_marker", text = trimmed, start = #indent + 1, finish = #line }
	end

	return {
		type = lt,
		text = line,
		indent = indent,
		tokens = tokens,
	}
end

return M
