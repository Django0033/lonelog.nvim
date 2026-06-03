local M = {}

-- Check if buffer already has YAML frontmatter
local function has_frontmatter(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 3, false)
	return lines[1] == "---"
end

-- Build the campaign header template
function M.build_campaign_header(title, ruleset, genre, player, pcs)
	local today = os.date("%Y-%m-%d")
	return {
		"---",
		"title: " .. title,
		"ruleset: " .. (ruleset or ""),
		"genre: " .. (genre or ""),
		"player: " .. (player or ""),
		"pcs: " .. (pcs or ""),
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

-- Update last_update field in existing frontmatter
function M.update_last_update(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 5, false)
	if lines[1] ~= "---" then
		return
	end
	local today = os.date("%Y-%m-%d")
	for i = 2, 5 do
		if lines[i]:match("^last_update:") then
			vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { "last_update: " .. today })
			return
		end
	end
end

-- Insert campaign header YAML frontmatter at top of buffer
function M.insert_campaign_header()
	local bufnr = vim.api.nvim_get_current_buf()

	if has_frontmatter(bufnr) then
		vim.notify("lonelog: Campaign header already exists", vim.log.levels.INFO)
		return
	end

	local fields = { "title", "ruleset", "genre", "player", "pcs" }
	local prompts = {
		title = "Campaign title: ",
		ruleset = "Ruleset (optional): ",
		genre = "Genre (optional): ",
		player = "Player name: ",
		pcs = "PCs (comma-separated): ",
	}
	local values = {}
	local idx = 1

	local function prompt_next()
		if idx > #fields then
			local cfg = require("lonelog.config").get()
			local lines = M.build_campaign_header(
				values.title,
				values.ruleset ~= "" and values.ruleset or cfg.campaign.default_ruleset,
				values.genre ~= "" and values.genre or cfg.campaign.default_genre,
				values.player ~= "" and values.player or cfg.campaign.default_player,
				values.pcs ~= "" and values.pcs or nil
			)
			vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
			vim.api.nvim_win_set_cursor(0, { 3, #"ruleset: " })
			return
		end

		local key = fields[idx]
		vim.ui.input({ prompt = prompts[key] }, function(input)
			if key == "title" and (not input or input == "") then
				return
			end
			values[key] = input or ""
			idx = idx + 1
			prompt_next()
		end)
	end

	prompt_next()
end

return M
