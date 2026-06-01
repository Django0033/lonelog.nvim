local M = {}

M.name = "combat"
M.description = "Combat blocks, round markers, and auto-roster"

M.commands = {
	{
		name = "LonelogCombat",
		command = function()
			require("lonelog.addons.combat.combat").insert_combat_block()
		end,
		opts = { nargs = 0, desc = "Insert combat block" },
	},
	{
		name = "LonelogRound",
		command = function()
			local round = require("lonelog.addons.combat.round")
			vim.ui.select({ "Simple round", "Round with roster" }, {
				prompt = "Insert round marker:",
			}, function(choice)
				if choice == "Simple round" then
					round.insert_round(false)
				elseif choice == "Round with roster" then
					round.insert_round(true)
				end
			end)
		end,
		opts = { nargs = 0, desc = "Insert round marker" },
	},
}

-- Uses config key names instead of resolved LHS; loader resolves at setup time
M.keymaps = {
	{ mode = "n", key = "combat_block", rhs = ":LonelogCombat<CR>",
		opts = { silent = true, desc = "Insert combat block" } },
	{ mode = "n", key = "insert_round", rhs = ":LonelogRound<CR>",
		opts = { silent = true, desc = "Insert round marker" } },
}

M.requires = {}

function M.setup() end

return M
