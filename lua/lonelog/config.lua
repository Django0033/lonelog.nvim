local M = {}

-- Default configuration values
local defaults = {
	keymaps = {
		-- Main actions (uppercase)
		oracle = "<leader>lO",
		dice = "<leader>lD",
		tags = "<leader>lT",
		scenes = "<leader>lS",
		chaos = "<leader>lC",
		session_header = "<leader>lH",
		narrative_block = "<leader>lN",
		insert_result = "<leader>lI",
		scene_marker = "<leader>lM",
		scene_prev = "<leader>l[",
		scene_next = "<leader>l]",
		roll_line = "<leader>lR",
		campaign_header = "<leader>lA",
		session_summary = "<leader>lE",

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
		d10 = "<leader>lda",
		d12 = "<leader>ldb",
		d20 = "<leader>ldw",
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
	return pcall(require, "telescope") and pcall(require, "telescope.pickers")
end

return M
