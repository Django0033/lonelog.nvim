local M = {}

function M.insert_text(text, cursor_offset)
	vim.api.nvim_put({ text }, "c", true, true)
	if cursor_offset then
		local row = vim.fn.line(".")
		local col = vim.fn.col(".") - cursor_offset
		vim.api.nvim_win_set_cursor(0, { row, col })
	end
end

function M.insert_template_at_cursor(template, cursor_line, cursor_col)
	local row = vim.fn.line(".") - 1
	local col = vim.fn.col(".") - 1
	vim.api.nvim_buf_set_text(0, row, col, row, col, template)
	vim.api.nvim_win_set_cursor(0, { row + 1 + cursor_line, cursor_col })
end

function M.insert_scene_marker()
	local scenes_mod = require("lonelog.parsers.scenes")
	local cfg = require("lonelog.config").get()
	local next_id = scenes_mod.generate_next_scene_id()

	local context
	if cfg.prompt_for_scene_context then
		context = vim.fn.input("Scene context: ")
		if context == "" then context = nil end
	end

	local text = scenes_mod.build_scene_line(next_id, context)
	local row = vim.fn.line(".") - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, { text, "" })
	vim.api.nvim_win_set_cursor(0, { row + 1, #("### " .. next_id .. " ") })
end

function M.do_insert_progress(type_key, name, max_default, label)
	if name then
		if type_key:upper() ~= "TIMER"
			and require("lonelog.commands.progress").check_needs_insert(type_key, name)
		then
			vim.ui.input({ prompt = "Max progress (default " .. max_default .. "): " }, function(m)
				local max_val = tonumber(m) or max_default
				require("lonelog.commands.progress").increment_progress(type_key, name, max_val)
			end)
		else
			require("lonelog.commands.progress").increment_progress(type_key, name, max_default)
		end
	else
		vim.ui.input({ prompt = label .. " name: " }, function(n)
			if n and n ~= "" then
				M.do_insert_progress(type_key, n, max_default, label)
			end
		end)
	end
end

M.QUICK_DICE = {
	{ key = "d4", cmd = "D4", dice = "1d4" },
	{ key = "d6", cmd = "D6", dice = "1d6" },
	{ key = "d8", cmd = "D8", dice = "1d8" },
	{ key = "d10", cmd = "D10", dice = "1d10" },
	{ key = "d12", cmd = "D12", dice = "1d12" },
	{ key = "d20", cmd = "D20", dice = "1d20" },
	{ key = "d100", cmd = "D100", dice = "1d100" },
}

M.ACTION_TEMPLATE = {
	"@ [action]",
	"d: [roll] -> [outcome]",
	"=> [consequence]",
}

M.ORACLE_TEMPLATE = {
	"? [question]",
	"-> [answer]",
	"=> [consequence]",
}

return M
