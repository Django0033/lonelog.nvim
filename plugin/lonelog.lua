-- Set up all plugin keybindings and commands

local setup_keymaps = require("lonelog.plugin.keymaps")
local register_commands = require("lonelog.plugin.commands")

-- Register all user commands
register_commands()

-- ================================================================
-- Addon loader
-- ================================================================

local addon_keymaps = {}

local function load_addons()
	local config = require("lonelog.config")
	local addons_config = config.get().addons or {}
	for name, enabled in pairs(addons_config) do
		if enabled then
			local ok, addon = pcall(require, "lonelog.addons." .. name)
			if ok and addon then
				for _, cmd in ipairs(addon.commands or {}) do
					vim.api.nvim_create_user_command(cmd.name, cmd.command, cmd.opts)
				end
				for _, km in ipairs(addon.keymaps or {}) do
					table.insert(addon_keymaps, km)
				end
				if addon.setup then
					addon.setup(addons_config[name] or {})
				end
			end
		end
	end
end

local function setup_addon_keymaps()
	local cfg = require("lonelog.config").get()
	for _, km in ipairs(addon_keymaps) do
		local lhs = cfg.keymaps[km.key]
		if lhs then
			vim.keymap.set(km.mode, lhs, km.rhs, km.opts)
		end
	end
end

load_addons()

-- Set up keymaps after plugin loads
vim.api.nvim_create_autocmd("User", {
	pattern = "LonelogLoaded",
	callback = function()
		setup_keymaps()
		setup_addon_keymaps()
	end,
})
vim.defer_fn(function()
	vim.api.nvim_exec_autocmds("User", { pattern = "LonelogLoaded" })
end, 0)

-- Autocommands
vim.api.nvim_create_augroup("LonelogCompletion", { clear = true })
vim.api.nvim_create_autocmd("TextChangedI", {
	group = "LonelogCompletion",
	pattern = "*",
	callback = function()
		if vim.bo.filetype ~= "markdown" then
			return
		end
		require("lonelog.completion").try_complete()
	end,
	desc = "Lonelog tag autocomplete",
})

vim.api.nvim_create_augroup("LonelogFrontmatter", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
	group = "LonelogFrontmatter",
	pattern = "*.md",
	callback = function()
		require("lonelog.commands.campaign").update_last_update()
	end,
	desc = "Update last_update in lonelog frontmatter",
})
