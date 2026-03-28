-- Set up all plugin keybindings
local function setup_keymaps()
	local cfg = require("lonelog.config")
	local solo = require("lonelog")
	local function map(mode, lhs, rhs, opts)
		vim.keymap.set(mode, lhs, rhs, opts or { silent = true })
	end

	-- Main features
	map("n", cfg.get().keymaps.oracle, function()
		solo.ui.pick({
			title = "Choose the Oracle",
			items = solo.oracle.list_tables(),
			on_select = function(t)
				solo.roll_oracle(t)
			end,
		})
	end, { desc = "Lonelog Oracle" })
	map("n", cfg.get().keymaps.dice, function()
		vim.ui.input({ prompt = "Dice (e.g., 2d6+3): " }, function(n)
			if n and n ~= "" then
				solo.roll_dice(n)
			end
		end)
	end, { desc = "Roll Dice" })
	map("n", cfg.get().keymaps.tags, function()
		solo.parsers.tags.show_tags_picker()
	end, { desc = "Navigate Tags" })
	map("n", cfg.get().keymaps.scenes, function()
		solo.parsers.scenes.show_scenes_picker()
	end, { desc = "Navigate Scenes" })
	map("n", cfg.get().keymaps.chaos, function()
		solo.oracle.show_chaos_ui()
	end, { desc = "Chaos Factor UI" })
	map("n", "<leader>li", function()
		local w, c = solo.ui.get_latest_content()
		if c then
			solo.ui.insert_result(w)
		else
			vim.notify("lonelog: No result to insert", vim.log.levels.WARN)
		end
	end, { desc = "Insert result" })

	-- Quick dice rolls (1d4, 1d6, etc.)
	local quick_dice = {
		{ key = "d4", dice = "1d4" },
		{ key = "d6", dice = "1d6" },
		{ key = "d8", dice = "1d8" },
		{ key = "d10", dice = "1d10" },
		{ key = "d12", dice = "1d12" },
		{ key = "d20", dice = "1d20" },
		{ key = "d100", dice = "1d100" },
	}
	for _, q in ipairs(quick_dice) do
		local km = cfg.get().keymaps[q.key]
		if km then
			map("n", km, function()
				solo.roll_dice(q.dice)
			end, { desc = "Roll " .. q.dice })
		end
	end

	-- Visual mode: use selection as oracle context or dice notation
	map("v", cfg.get().keymaps.oracle, function()
		local t = vim.trim(vim.fn.getline("."):sub(vim.fn.col("v"), vim.fn.col(".")))
		solo.roll_oracle(t == "" and nil or t)
	end, { desc = "Oracle with selection" })
	map("v", cfg.get().keymaps.dice, function()
		local n = vim.trim(vim.fn.getline("."):sub(vim.fn.col("v"), vim.fn.col(".")))
		if n ~= "" then
			solo.roll_dice(n)
		end
	end, { desc = "Roll dice with selection" })
end

-- Create Vim commands
vim.api.nvim_create_user_command("LonelogOracle", function(o)
	require("lonelog").roll_oracle(o.args ~= "" and o.args or nil)
end, { nargs = "?", desc = "Roll the oracle" })
vim.api.nvim_create_user_command("LonelogDice", function()
	vim.ui.input({ prompt = "Dice (e.g., 2d6+3): " }, function(n)
		if n and n ~= "" then
			require("lonelog").roll_dice(n)
		end
	end)
end, { nargs = 0, desc = "Interactive dice roller" })
vim.api.nvim_create_user_command("LonelogDiceRoll", function(o)
	require("lonelog").roll_dice(o.args)
end, {
	nargs = 1,
	complete = function()
		return {
			"1d4",
			"1d6",
			"1d8",
			"1d10",
			"1d12",
			"1d20",
			"1d100",
			"2d6",
			"2d6+3",
			"4d6",
			"6d6>>4",
			"2d6>7",
			"1d20>10",
		}
	end,
	desc = "Roll dice with notation",
})
vim.api.nvim_create_user_command("LonelogTags", function()
	require("lonelog.ui.parsers").tags.show_tags_picker()
end, { nargs = 0, desc = "Navigate tags" })
vim.api.nvim_create_user_command("LonelogScenes", function()
	require("lonelog.ui.parsers").scenes.show_scenes_picker()
end, { nargs = 0, desc = "Navigate scenes" })
vim.api.nvim_create_user_command("Lonelog", function()
	require("lonelog").open_picker()
end, { nargs = 0, desc = "Open Lonelog picker" })
vim.api.nvim_create_user_command("LonelogInsert", function()
	local ui = require("lonelog.ui")
	local w, c = ui.get_latest_content()
	if c then
		ui.insert_result(w)
	else
		vim.notify("lonelog: No result to insert", vim.log.levels.WARN)
	end
end, { nargs = 0, desc = "Insert last result" })

-- Quick dice commands
for _, d in ipairs({
	{ "D4", "1d4" },
	{ "D6", "1d6" },
	{ "D8", "1d8" },
	{ "D10", "1d10" },
	{ "D12", "1d12" },
	{ "D20", "1d20" },
	{ "D100", "1d100" },
}) do
	vim.api.nvim_create_user_command("Lonelog" .. d[1], function()
		require("lonelog").roll_dice(d[2])
	end, { nargs = 0, desc = "Roll " .. d[2] })
end

-- Set up keymaps after plugin loads
vim.api.nvim_create_autocmd("User", { pattern = "LonelogLoaded", callback = setup_keymaps })
vim.defer_fn(function()
	vim.api.nvim_exec_autocmds("User", { pattern = "LonelogLoaded" })
end, 0)

vim.api.nvim_create_user_command("LonelogChaos", function()
	require("lonelog.oracle").show_chaos_ui()
end, { nargs = 0, desc = "Open Chaos Factor UI" })
