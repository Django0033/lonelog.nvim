local M = {}

M.name = "combat"
M.description = "Combat blocks, round markers, and auto-roster"

local function show_combat_status()
	local cache = require("lonelog.cache")
	local blocks = cache.get().combat
	if #blocks == 0 then
		vim.notify("lonelog: No combat blocks found", vim.log.levels.INFO)
		return
	end
	local lines = {}
	for i, blk in ipairs(blocks) do
		local status = blk.is_closed and "closed" or "open"
		table.insert(lines, string.format("Block %d: Round %d/%d %s",
			i, blk.current_round, blk.current_round, status))
		local alive_pcs, alive_foes, dead = {}, {}, {}
		for _, c in ipairs(blk.combatants or {}) do
			if c.is_dead then
				table.insert(dead, c.name)
			elseif c.type == "PC" then
				table.insert(alive_pcs, string.format("%s (%s)", c.name, table.concat(c.stats, ", ")))
			else
				table.insert(alive_foes, string.format("%s (%s)", c.name, table.concat(c.stats, ", ")))
			end
		end
		table.insert(lines, "  PCs: " .. (#alive_pcs > 0 and table.concat(alive_pcs, ", ") or "none"))
		table.insert(lines, "  Foes: " .. (#alive_foes > 0 and table.concat(alive_foes, ", ") or "none"))
		if #dead > 0 then
			table.insert(lines, "  Dead: " .. table.concat(dead, ", "))
		end
		if i < #blocks then table.insert(lines, "") end
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

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
	{
		name = "LonelogCombatStatus",
		command = show_combat_status,
		opts = { nargs = 0, desc = "Show combat status overview" },
	},
}

-- Uses config key names instead of resolved LHS; loader resolves at setup time
M.keymaps = {
	{ mode = "n", key = "combat_block", rhs = ":LonelogCombat<CR>",
		opts = { silent = true, desc = "Insert combat block" } },
	{ mode = "n", key = "insert_round", rhs = ":LonelogRound<CR>",
		opts = { silent = true, desc = "Insert round marker" } },
	{ mode = "n", key = "combat_status", rhs = ":LonelogCombatStatus<CR>",
		opts = { silent = true, desc = "Show combat status overview" } },
}

M.requires = {}

function M.setup() end

return M
