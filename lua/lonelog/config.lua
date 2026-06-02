local M = {}

-- Default configuration values
local defaults = {
	keymaps = {
		-- Core actions (uppercase)
		oracle = "<leader>lO",
		dice = "<leader>lD",
		tags = "<leader>lT",
		scenes = "<leader>lS",
		chaos = "<leader>lC",
		insert_result = "<leader>lI",
		roll_line = "<leader>lR",

		-- Session structure (ls-)
		session_header = "<leader>lsh",
		campaign_header = "<leader>lsc",
		scene_marker = "<leader>lsm",
		narrative_block = "<leader>lsn",
		session_summary = "<leader>lss",
		scene_prev = "<leader>l[",
		scene_next = "<leader>l]",

		-- Addons (lx-)
		combat_block = "<leader>lxc",
		dungeon_status = "<leader>lxd",
		room_go = "<leader>lxg",
		room_state = "<leader>lxs",
		insert_round = "<leader>lxr",
		resources_block = "<leader>lrr",
		wealth_delta = "<leader>lwd",

		-- Insert notation symbols
		insert_action = "<leader>lia",
		insert_question = "<leader>liq",
		insert_dice = "<leader>lid",
		insert_note = "<leader>lin",
		insert_arrow = "<leader>li-",
		insert_conseq = "<leader>li=",
		actor_action = "<leader>liN",
		action_seq = "<leader>liA",
		oracle_seq = "<leader>liQ",

		-- Entity tags
		tag_npc = "<leader>ltn",
		tag_location = "<leader>ltl",
		tag_pc = "<leader>ltp",
		tag_thread = "<leader>ltt",
		tag_ref = "<leader>ltr",
		tag_foe = "<leader>ltf",
		tag_room = "<leader>ltm",
		tag_inv = "<leader>lti",
		tag_wealth = "<leader>ltw",
		pc_update = "<leader>ltx",
		npc_update = "<leader>ltz",

		-- Multi-line tags
		mltag_npc = "<leader>lmn",
		mltag_location = "<leader>lml",
		mltag_pc = "<leader>lmp",
		mltag_thread = "<leader>lmt",
		mltag_ref = "<leader>lmr",
		mltag_foe = "<leader>lmf",

		-- Progress elements
		progress_clock = "<leader>lpc",
		progress_track = "<leader>lpt",
		progress_timer = "<leader>lpi",

		-- Quick dice
		d4 = "<leader>ld4",
		d6 = "<leader>ld6",
		d8 = "<leader>ld8",
		d10 = "<leader>ldx",
		d12 = "<leader>ldz",
		d20 = "<leader>ldt",
		d100 = "<leader>ldc",

		-- Tag completion (insert mode)
		complete_tag = "<C-l>c",
	},
	use_telescope = "auto",
	sidebar = { width = 50 },
	float = { border = "rounded", height = 0.4, width = 0.6 },
	oracle = {
		default_table = "fate",
		persist_chaos = true,
		chaos_file = "chaos_factor.json",
	},
	dice = { max_dice = 100, max_sides = 1000 },
	prompt_for_scene_context = true,
	campaign = {
		default_ruleset = "",
		default_genre = "",
		default_player = "",
	},
	addons = {
		combat = false,
		dungeon = false,
		resources = false,
	},
	highlight = {},
}

M.options = vim.deepcopy(defaults)

-- Merge user options with defaults
function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

-- Get current configuration
function M.get()
	return M.options
end

-- Check if we should use Telescope picker
-- Returns: true if Telescope should be used, false for native sidebar
function M.should_use_telescope()
	local use = M.options.use_telescope
	if use == true then
		return true
	end
	if use == false then
		return false
	end
	return pcall(require, "telescope")
end

return M
