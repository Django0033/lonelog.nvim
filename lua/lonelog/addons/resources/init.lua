local M = {}

M.name = "resources"
M.description = "Inventory, wealth, and supply dice tracking"

local function insert_wealth_tag()
	vim.api.nvim_put({ "[Wealth:Gold 0]" }, "c", true, true)
	local row, col = vim.fn.line("."), vim.fn.col(".")
	vim.api.nvim_win_set_cursor(0, { row, col - 2 })
end

M.commands = {
	{
		name = "LonelogResourcesBlock",
		command = function()
			require("lonelog.addons.resources.resources").insert_block()
		end,
		opts = { nargs = 0, desc = "Insert resources status block" },
	},
	{
		name = "LonelogSupplyRoll",
		command = function()
			require("lonelog.addons.resources.supply").roll_supply()
		end,
		opts = { nargs = 0, desc = "Roll supply die and degrade if needed" },
	},
}

M.keymaps = {
	{ mode = "n", key = "tag_inv",
		rhs = function()
			vim.api.nvim_put({ "[Inv:|]" }, "c", true, true)
			local row, col = vim.fn.line("."), vim.fn.col(".")
			vim.api.nvim_win_set_cursor(0, { row, col - 2 })
		end,
		opts = { silent = true, desc = "Insert inventory tag [Inv:]" } },
	{ mode = "n", key = "tag_wealth", rhs = insert_wealth_tag,
		opts = { silent = true, desc = "Insert wealth tag [Wealth:]" } },
	{ mode = "n", key = "resources_block",
		rhs = ":LonelogResourcesBlock<CR>",
		opts = { silent = true, desc = "Insert resources status block" } },
}

M.requires = {}

function M.setup() end

return M
