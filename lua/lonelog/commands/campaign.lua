local M = {}

-- Check if buffer already has YAML frontmatter
local function has_frontmatter(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 3, false)
	return lines[1] == "---"
end

-- Build the campaign header template
function M.build_campaign_header(title)
	local today = os.date("%Y-%m-%d")
	return {
		"---",
		"title: " .. title,
		"ruleset: ",
		"genre: ",
		"player: ",
		"pcs: ",
		"start_date: " .. today,
		"last_update: " .. today,
		"tools: ",
		"themes: ",
		"tone: ",
		"notes: ",
		"---",
		"",
		"# " .. title,
	}
end

-- Insert campaign header YAML frontmatter at top of buffer
function M.insert_campaign_header()
	local bufnr = vim.api.nvim_get_current_buf()

	if has_frontmatter(bufnr) then
		vim.notify("lonelog: Campaign header already exists", vim.log.levels.INFO)
		return
	end

	vim.ui.input({ prompt = "Campaign title: " }, function(title)
		if not title or title == "" then
			return
		end

		local lines = M.build_campaign_header(title)
		vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
		vim.api.nvim_win_set_cursor(0, { 3, #"ruleset: " })
	end)
end

return M
