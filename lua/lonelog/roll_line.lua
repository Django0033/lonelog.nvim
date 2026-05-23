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
	if header and header.dice then
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
		if not info or not info.dice then
			return nil
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

	return nil
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

	local tables = tp().parse_tables(lines)
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
