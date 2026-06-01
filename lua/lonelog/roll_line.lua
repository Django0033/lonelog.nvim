local M = {}
local tables_parser = nil

local function tp()
	if not tables_parser then
		tables_parser = require("lonelog.parsers.tables")
	end
	return tables_parser
end

local function normalize(notation)
	if notation:match("^[dD]") then
		return "1" .. notation
	end
	return notation
end

local function parse_tbl_line(line)
	local T = tp()
	local header = T.parse_header(line)
	if header then
		return header
	end
	local rolled = T.parse_roll_line(line)
	if rolled and rolled.dice then
		return { name = rolled.name, dice = rolled.dice }
	end
	return nil
end

local function extract_d_notation(line)
	return line:match("^%s*d:%s*([%w%+%-%>%%%!%#]+)")
end

local function extract_label_notation(line)
	local trimmed = line:match("^%s*(.-)%s*$")
	if not trimmed then return nil end
	if trimmed:lower():match("^[tdg]%l+:") then return nil end
	local _, _, label, notation = trimmed:find("^([^:([]+):%s*(%d*[dD][%d]+)")
	if not label or not notation then return nil end
	return {
		label = label:match("^%s*(.-)%s*$"):lower(),
		notation = notation,
	}
end

function M.process_line(line, tables)
	if not line then
		return nil
	end
	local trimmed = line:match("^%s*(.-)%s*$")
	if not trimmed or trimmed == "" then
		return nil
	end

	local lower = trimmed:lower()

	if lower:match("^tbl:") then
		local info = parse_tbl_line(line)
		if not info then
			return nil
		end

		if not info.dice then
			local table_def = tables and tables[info.name:lower()]
			if table_def and table_def.dice then
				info.dice = table_def.dice
			else
				return nil
			end
		end

		local table_def = tables and tables[info.name:lower()]
		if not table_def then
			return nil
		end

		local dice_notation = normalize(info.dice)
		local dice = require("lonelog.dice")
		local result, err = dice.roll(dice_notation)
		if not result then
			return nil, err
		end

		local entry_text = tp().resolve_entry(table_def, result.total)
		local indent = line:match("^(%s*)")
		local output = indent .. "tbl: " .. info.name .. " " .. info.dice .. "=" .. result.total
		if entry_text then
			output = output .. " -> " .. entry_text
		end
		return output
	end

	if lower:match("^d:") then
		local notation = extract_d_notation(line)
		if not notation then
			return nil
		end

		local dice = require("lonelog.dice")
		local result, err = dice.roll(notation)
		if not result then
			return nil, err
		end

		local indent = line:match("^(%s*)")
		return indent .. "d: " .. result.display
	end

	local label_info = extract_label_notation(line)
	if label_info then
		local table_def = tables and tables[label_info.label]
		local dice_notation = normalize(label_info.notation)
		local dice = require("lonelog.dice")
		local result, err = dice.roll(dice_notation)
		if not result then
			return nil, err
		end

		local entry_text = table_def and tp().resolve_entry(table_def, result.total)
		local indent = line:match("^(%s*)")
		local _, _, orig_label, orig_notation = line:find("^%s*([^:([]+):%s*(%d*[dD][%d]+)")
		local output = indent .. orig_label .. ": " .. orig_notation .. "=" .. result.total
		if entry_text then
			output = output .. " -> " .. entry_text
		end
		return output
	end

	if not lower:match("^[tdg]%l+:") then
		local bare_notation = trimmed:match("^(%d*[dD][%d]+)$")
		if bare_notation then
			local dice_notation = normalize(bare_notation)
			local dice = require("lonelog.dice")
			local result, err = dice.roll(dice_notation)
			if not result then return nil, err end
			local indent = line:match("^(%s*)")
			return indent .. bare_notation .. "=" .. result.total
		end
	end

	return nil
end

function M.process_gen_block(header_line_num, lines, tables)
	if not lines or #lines == 0 then return {} end
	local changes = {}
	local i = header_line_num + 1
	while i <= #lines do
		local next_line = lines[i]
		if not next_line then break end
		if next_line:match("^%s+") then
			local result, err = M.process_line(next_line, tables)
			if result then
				table.insert(changes, { index = i, text = result })
			end
			i = i + 1
		elseif next_line:match("^%s*$") then
			i = i + 1
		else
			break
		end
	end
	return changes
end

function M.roll_current_line()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor[1]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current_line = lines[line_num]

	if not current_line then
		vim.notify("lonelog: No line to roll", vim.log.levels.WARN)
		return
	end

	local trimmed = current_line:match("^%s*(.-)%s*$")
	local tables = tp().parse_tables(lines)

	if trimmed and trimmed:lower():match("^gen:") then
		local changes = M.process_gen_block(line_num, lines, tables)
		if #changes == 0 then
			vim.notify("lonelog: No indented dice lines to roll under gen:", vim.log.levels.INFO)
			return
		end
		for _, change in ipairs(changes) do
			vim.api.nvim_buf_set_lines(bufnr, change.index - 1, change.index, false, { change.text })
		end
		return
	end

	local result, err = M.process_line(current_line, tables)
	if not result then
		if err then
			vim.notify("lonelog: " .. tostring(err), vim.log.levels.ERROR)
		else
			vim.notify("lonelog: No dice notation found on this line", vim.log.levels.INFO)
		end
		return
	end

	vim.api.nvim_buf_set_lines(bufnr, line_num - 1, line_num, false, { result })
end

return M
