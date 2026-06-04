local M = {}

-- Load all submodules
M.config = require("lonelog.config")
M.dice = require("lonelog.dice")
M.oracle = require("lonelog.oracle")
M.ui = require("lonelog.ui")
M.parsers = require("lonelog.ui.parsers")

-- Initialize plugin with user configuration
function M.setup(opts)
	M.config.setup(opts)
	M.dice.setup()
	M.oracle.load_chaos()

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "markdown",
		group = vim.api.nvim_create_augroup("LonelogSyntax", { clear = true }),
		callback = function()
			vim.cmd("runtime! after/syntax/markdown/lonelog.vim")
			for group, opts in pairs(M.config.get().highlight or {}) do
				if vim.fn.hlexists(group) > 0 then
					vim.api.nvim_set_hl(0, group, opts)
				end
			end
		end,
		desc = "Load lonelog syntax highlighting for markdown buffers",
	})
end

-- Roll dice and show result in floating window
function M.roll_dice(notation)
	local result, err = M.dice.roll(notation)
	if err then
		vim.notify("lonelog: " .. err, vim.log.levels.ERROR)
		return nil, err
	end
	-- Capture to history before showing UI
	local bufnr = vim.api.nvim_get_current_buf()
	M.dice.add_to_history(bufnr, result, vim.fn.line("."))
	M.ui.show_dice_result(result)
	vim.cmd("echo '" .. result.display .. "'")
	return result
end

-- Roll oracle and show result
-- For mythic: prompts for chaos factor first
-- For others: rolls immediately
function M.roll_oracle(table_name)
	if table_name and table_name:lower() == "mythic" then
		local chaos = M.oracle.get_chaos()
		vim.ui.input(
			{ prompt = string.format("Chaos factor (1-9, default %d, +/- to change): ", chaos) },
			function(input)
				if input == "+" then
					chaos = math.min(chaos + 1, 9)
				elseif input == "-" then
					chaos = math.max(chaos - 1, 1)
				else
					local n = tonumber(input)
					if n and n >= 1 and n <= 9 then
						chaos = n
					end
				end
				M.oracle.set_chaos(chaos)
				local result = M.oracle.roll("mythic")
				-- Capture to history before showing UI
				local bufnr = vim.api.nvim_get_current_buf()
				M.oracle.add_to_history(bufnr, result, vim.fn.line("."))
				M.ui.show_oracle_result(result)
				vim.cmd("echo '" .. M.oracle.format_result(result) .. "'")
			end
		)
		return
	end
	local result, err = M.oracle.roll(table_name)
	if err then
		vim.notify("lonelog: " .. err, vim.log.levels.ERROR)
		return nil, err
	end
	-- Capture to history before showing UI
	local bufnr = vim.api.nvim_get_current_buf()
	M.oracle.add_to_history(bufnr, result, vim.fn.line("."))
	M.ui.show_oracle_result(result)
	vim.cmd("echo '" .. M.oracle.format_result(result) .. "'")
	return result
end

-- Open main picker with all available actions
function M.open_picker()
	M.ui.pick({
		title = "Lonelog",
		items = {
			{ label = "Oracle", action = "oracle" },
			{ label = "Dice Roll", action = "dice" },
			{ label = "Navigate Tags", action = "tags" },
			{ label = "Navigate Scenes", action = "scenes" },
		},
		format_item = function(i)
			return i.label
		end,
		on_select = function(i)
			if i.action == "oracle" then
				M.ui.pick({
					title = "Choose the Oracle",
					items = M.oracle.list_tables(),
					on_select = function(t)
						M.roll_oracle(t)
					end,
				})
			elseif i.action == "dice" then
				vim.ui.input({ prompt = "Dice (e.g., 2d6+3): " }, function(n)
					if n and n ~= "" then
						M.roll_dice(n)
					end
				end)
			elseif i.action == "tags" then
				M.parsers.tags.show_tags_picker()
			elseif i.action == "scenes" then
				M.parsers.scenes.show_scenes_picker()
			end
		end,
	})
end

return M
