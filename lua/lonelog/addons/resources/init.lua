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
	{
		name = "LonelogWealthDelta",
		command = function()
			require("lonelog.addons.resources.resources").wealth_delta()
		end,
		opts = { nargs = "?", desc = "Add or subtract wealth" },
	},
	{
		name = "LonelogInvDelta",
		command = function()
			require("lonelog.addons.resources.resources").inv_delta()
		end,
		opts = { nargs = "?", desc = "Add or subtract inventory quantity" },
	},
	{
		name = "LonelogItemState",
		command = function()
			require("lonelog.addons.resources.resources").item_state()
		end,
		opts = { nargs = "?", desc = "Add/remove item properties" },
	},
	{
		name = "LonelogSlotInsert",
		command = function()
			require("lonelog.addons.resources.resources").slot_insert()
		end,
		opts = { nargs = 0, desc = "Insert inventory slot tag" },
	},
	{
		name = "LonelogSlotSummary",
		command = function()
			require("lonelog.addons.resources.resources").slot_summary()
		end,
		opts = { nargs = 0, desc = "Show inventory slot summary" },
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
	{ mode = "n", key = "wealth_delta", rhs = ":LonelogWealthDelta<CR>",
		opts = { silent = true, desc = "Add/subtract wealth" } },
	{ mode = "n", key = "inv_delta", rhs = ":LonelogInvDelta<CR>",
		opts = { silent = true, desc = "Add/subtract inventory" } },
	{ mode = "n", key = "item_state", rhs = ":LonelogItemState<CR>",
		opts = { silent = true, desc = "Change item properties" } },
	{ mode = "n", key = "slot_insert", rhs = ":LonelogSlotInsert<CR>",
		opts = { silent = true, desc = "Insert inventory slot" } },
}

M.requires = {}

function M.setup() end

return M
