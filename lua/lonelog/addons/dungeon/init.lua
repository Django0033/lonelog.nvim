local M = {}

M.name = "dungeon"
M.description = "Dungeon status block, room navigation, and room state editor"

M.commands = {
	{
		name = "LonelogDungeonStatus",
		command = function()
			require("lonelog.addons.dungeon.dungeon_status").insert_status_block()
		end,
		opts = { nargs = 0, desc = "Insert/update dungeon status block" },
	},
	{
		name = "LonelogRoomGo",
		command = function()
			require("lonelog.addons.dungeon.room_nav").navigate_to_room()
		end,
		opts = { nargs = 0, desc = "Navigate to a connected room" },
	},
	{
		name = "LonelogRoomState",
		command = function()
			require("lonelog.addons.dungeon.room_state").edit_room_state()
		end,
		opts = { nargs = 0, desc = "Toggle room state" },
	},
}

-- Uses config key names instead of resolved LHS; loader resolves at setup time
M.keymaps = {
	{ mode = "n", key = "dungeon_status", rhs = ":LonelogDungeonStatus<CR>",
		opts = { silent = true, desc = "Insert/update dungeon status block" } },
	{ mode = "n", key = "room_go", rhs = ":LonelogRoomGo<CR>",
		opts = { silent = true, desc = "Navigate to connected room" } },
	{ mode = "n", key = "room_state", rhs = ":LonelogRoomState<CR>",
		opts = { silent = true, desc = "Toggle room state" } },
}

M.requires = {}

function M.setup() end

return M
