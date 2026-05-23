#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

_G.vim = {
	split = function(s, sep)
		local r = {}
		for w in s:gmatch("[^" .. sep .. "]+") do
			r[#r + 1] = w
		end
		return r
	end,
	trim = function(s)
		return s:match("^%s*(.-)%s*$") or s
	end,
	log = { levels = { WARN = 1, ERROR = 2, INFO = 3 } },
	api = {
		nvim_get_current_buf = function() return 1 end,
		nvim_win_get_cursor = function() return { 1, 0 } end,
		nvim_buf_get_lines = function() return {} end,
		nvim_buf_set_lines = function() end,
	},
	notify = function() end,
}

local function reset_state()
	_G.vim.api.nvim_buf_get_lines = function() return {} end
	_G.vim.api.nvim_buf_set_lines = function() end
	_G.vim.notify = function() end
end

-- Mock dice for deterministic results
package.preload["lonelog.dice"] = function()
	return {
		roll = function(notation)
			local mocks = {
				["1d6"] = { total = 4, rolls = { 4 }, display = "1d6[4] = 4" },
				["1d20"] = { total = 15, rolls = { 15 }, display = "1d20[15] = 15" },
				["2d6+3"] = { total = 10, rolls = { 4, 3 }, display = "2d6+3[4, 3] = 10" },
			}
			return mocks[notation] or { total = 3, rolls = { 3 }, display = "1d6[3] = 3" }
		end,
	}
end

local roll_line = require("lonelog.roll_line")
local T = require("lonelog.parsers.tables")

local function test(name, ok)
	if ok then
		print("  PASS " .. name)
	else
		print("  FAIL " .. name)
	end
	return ok
end

local passed = 0
local failed = 0

local test_tables = T.parse_tables({
	"tbl: Forest (d6)",
	"  1-3: Nothing",
	"  4-5: Deer",
	"  6: Ambush",
	"tbl: Weather [Sunny, Rain, Storm]",
	"tbl: Empty (d20)",
	"tbl: Items (d6)",
	"  1: Simple stuff",
})

print("=== process_line (tbl: lines) ===")

do
	local r = roll_line.process_line("tbl: Forest (d6)", test_tables)
	local ok = r ~= nil and r:match("tbl: Forest d6=4") and r:match("-> Deer")
	if test("range table resolves entry", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("tbl: Weather [Sunny, Rain, Storm]", test_tables)
	local ok = r ~= nil and r:match("tbl: Weather d3=3") and r:match("-> Storm")
	if test("bracket table resolves entry", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("tbl: Unknown (d6)", test_tables)
	if test("unknown table returns nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("tbl: Empty (d20)", test_tables)
	local ok = r ~= nil and r:match("d20=15") and not r:match("->")
	if test("empty entries skips arrow", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("  tbl: Items (d6)", test_tables)
	local ok = r ~= nil and r:match("^  tbl: Items d6=4")
	if test("indented line preserves indent", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

print()
print("=== process_line (d: lines) ===")

do
	local r = roll_line.process_line("d: 2d6+3", test_tables)
	if test("d: notation rolls and appends", r ~= nil and r:match("^d:") and r:match("2d6%+3")) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("d: 1d6", test_tables)
	if test("d: single die", r ~= nil and r:match("^d: 1d6%[4%] = 4")) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

print()
print("=== process_line (no match cases) ===")

do
	local r = roll_line.process_line("not a table or dice line", test_tables)
	if test("plain text returns nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("", test_tables)
	if test("empty line returns nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line("  ", test_tables)
	if test("whitespace line returns nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = roll_line.process_line(nil, test_tables)
	if test("nil line returns nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

print()
print("=== roll_current_line (Neovim integration) ===")

do
	reset_state()
	local set_lines_args = nil
	_G.vim.api.nvim_buf_get_lines = function() return { "", "tbl: Forest (d6)" } end
	_G.vim.api.nvim_buf_set_lines = function(bufnr, start, e, strict, lines)
		set_lines_args = { bufnr = bufnr, start = start, e = e, lines = lines }
	end
	_G.vim.api.nvim_win_get_cursor = function() return { 2, 0 } end

	roll_line.roll_current_line()

	local ok = set_lines_args ~= nil
		and set_lines_args.start == 1
		and set_lines_args.e == 2
		and set_lines_args.lines[1]:match("tbl: Forest d6=4")
	if test("roll_current_line replaces line", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	reset_state()
	local notified = nil
	_G.vim.api.nvim_buf_get_lines = function() return { "", "plain text" } end
	_G.vim.notify = function(msg, level)
		notified = { msg = msg, level = level }
	end
	_G.vim.api.nvim_win_get_cursor = function() return { 2, 0 } end

	roll_line.roll_current_line()

	if test("no notation notifies info", notified ~= nil and notified.msg:match("No dice notation")) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	reset_state()
	local notified = nil
	_G.vim.api.nvim_buf_get_lines = function() return {} end
	_G.vim.notify = function(msg, level)
		notified = { msg = msg, level = level }
	end
	_G.vim.api.nvim_win_get_cursor = function() return { 1, 0 } end

	roll_line.roll_current_line()

	if test("no line notifies warn", notified ~= nil and notified.msg:match("No line to roll")) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

print()
print("=" .. string.rep("=", 60))
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 60))

if failed > 0 then
	os.exit(1)
end
