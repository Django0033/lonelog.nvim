local M = {}

-- Default configuration values
local defaults = {
	keymaps = {
		oracle = "<leader>lo",
		dice = "<leader>ldr",
		tags = "<leader>lt",
		scenes = "<leader>ls",
		d4 = "<leader>ld4",
		d6 = "<leader>ld6",
		d8 = "<leader>ld8",
		d10 = "<leader>lda",
		d12 = "<leader>ldb",
		d20 = "<leader>ldw",
		d100 = "<leader>ldc",
		chaos = "<leader>lC",
		insert_action = "<leader>la",
		insert_question = "<leader>lq",
		insert_dice = "<leader>ldd",
		insert_arrow = "<leader>l-",
		insert_conseq = "<leader>l=",
		action_seq = "<leader>lA",
		oracle_seq = "<leader>lQ",
		tag_npc = "<leader>ln",
		tag_location = "<leader>ll",
		tag_pc = "<leader>lp",
		tag_thread = "<leader>lth",
		tag_ref = "<leader>lr",
		tag_foe = "<leader>lf",
		scene_marker = "<leader>lm",
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
