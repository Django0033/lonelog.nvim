-- Facade: re-exports functions from submodules for backward compatibility

local wealth = require("lonelog.addons.resources.wealth")
local inventory = require("lonelog.addons.resources.inventory")
local slots = require("lonelog.addons.resources.slots")

local M = {}

function M.build_block(inv_items, wealth_items)
	local lines = { "--- RESOURCES ---" }
	for _, item in ipairs(inv_items or {}) do
		table.insert(lines, item)
	end
	for _, w in ipairs(wealth_items or {}) do
		table.insert(lines, w)
	end
	table.insert(lines, "---")
	return lines
end

function M.collect_items(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local inv_items = {}
	local wealth_items = {}
	for _, line in ipairs(lines) do
		local inv = line:match("%[Inv:[^%]]+%]")
		if inv then table.insert(inv_items, inv) end
		local wealth = line:match("%[Wealth:[^%]]+%]")
		if wealth then table.insert(wealth_items, wealth) end
	end
	return inv_items, wealth_items
end

function M.insert_block()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local inv_items, wealth_items = M.collect_items(bufnr)
	local block = M.build_block(inv_items, wealth_items)
	if #block <= 2 then
		vim.notify("lonelog: No inventory or wealth tags found", vim.log.levels.INFO)
		return
	end
	vim.api.nvim_buf_set_lines(bufnr, cursor[1], cursor[1], false, block)
end

M.wealth_delta = wealth.wealth_delta
M.inv_delta = inventory.inv_delta
M.item_state = inventory.item_state
M.slot_insert = slots.slot_insert
M.slot_summary = slots.slot_summary

return M
