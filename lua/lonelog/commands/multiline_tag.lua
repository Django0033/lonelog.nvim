local M = {}

local TAG_KEYS = {
	npc = "N",
	location = "L",
	pc = "PC",
	thread = "THREAD",
	ref = "#N",
	foe = "F",
}

function M.insert_multiline_tag(tag_key)
	local type_upper = TAG_KEYS[tag_key]
	if not type_upper then
		vim.notify("lonelog: Unknown tag type '" .. tostring(tag_key) .. "'", vim.log.levels.ERROR)
		return
	end

	vim.ui.input({ prompt = type_upper .. " name: " }, function(name)
		if not name or name == "" then
			return
		end

		local row = vim.fn.line(".") - 1
		local template = { "[" .. type_upper .. ":" .. name, "  | ", "]" }
		vim.api.nvim_buf_set_text(0, row, 0, row, 0, template)
		vim.api.nvim_win_set_cursor(0, { row + 2, 4 })
		vim.cmd("startinsert!")
	end)
end

return M
