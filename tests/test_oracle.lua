#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

-- Minimal vim mock for standalone test environment
_G.vim = {
	deepcopy = function(t)
		if type(t) ~= "table" then return t end
		local r = {}
		for k, v in pairs(t) do
			r[k] = _G.vim.deepcopy(v)
		end
		return r
	end,
	tbl_deep_extend = function(_, t1, t2)
		local r = _G.vim.deepcopy(t1)
		for k, v in pairs(t2 or {}) do
			if type(v) == "table" and type(r[k]) == "table" then
				r[k] = _G.vim.tbl_deep_extend("force", r[k], v)
			else
				r[k] = _G.vim.deepcopy(v)
			end
		end
		return r
	end,
	fn = {
		stdpath = function(_) return "/tmp/lonelog-test" end,
		mkdir = function(_, _) end,
	},
	keymap = { set = function() end },
	api = {
		nvim_create_buf = function() return 1 end,
		nvim_open_win = function() return 1 end,
		nvim_buf_set_lines = function() end,
		nvim_win_close = function() end,
	},
	o = { lines = 40, columns = 80 },
}

local oracle = require("lonelog.oracle")

local passed = 0
local failed = 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		print("  PASS " .. name)
		passed = passed + 1
	else
		print("  FAIL " .. name)
		print("    " .. tostring(err))
		failed = failed + 1
	end
	return ok
end

local function assert_eq(a, b, msg)
	if a ~= b then
		error((msg or "assertion failed") .. ": got " .. tostring(a) .. ", expected " .. tostring(b))
	end
end

local function assert_nil(val, msg)
	if val ~= nil then
		error((msg or "expected nil") .. ": got " .. tostring(val))
	end
end

print("list_tables:")
test("returns sorted deterministic order", function()
	local r1 = oracle.list_tables()
	local r2 = oracle.list_tables()
	assert_eq(#r1, 3, "expected 3 tables")
	for i = 1, #r1 do
		assert_eq(r1[i], r2[i], "order differs between calls at " .. i)
	end
end)

test("returns Binary, Fate, Mythic", function()
	local r = oracle.list_tables()
	assert_eq(r[1], "Binary", "first should be Binary")
	assert_eq(r[2], "Fate", "second should be Fate")
	assert_eq(r[3], "Mythic", "third should be Mythic")
end)

print("roll:")
test("rolls fate oracle successfully", function()
	local r = oracle.roll("fate")
	assert(r ~= nil, "result should not be nil")
	assert_eq(r.table, "fate")
	assert(r.display ~= nil, "display should not be nil")
end)

test("rolls binary oracle successfully", function()
	local r = oracle.roll("binary")
	assert(r ~= nil)
	assert_eq(r.table, "binary")
end)

test("rolls mythic oracle successfully", function()
	local r = oracle.roll("mythic")
	assert(r ~= nil)
	assert_eq(r.table, "mythic")
	assert(r.chaos ~= nil, "mythic should have chaos")
	assert(r.dice_total ~= nil, "mythic should have dice_total")
end)

test("rolls default oracle when no table given", function()
	local r = oracle.roll()
	assert(r ~= nil)
	assert(r.display ~= nil)
end)

test("returns error for unknown oracle table", function()
	local r, err = oracle.roll("nonexistent")
	assert_nil(r, "result should be nil for unknown table")
	assert(err ~= nil, "should return error message")
end)

print("chaos_factor:")
test("get/set chaos factor", function()
	local orig = oracle.get_chaos()
	assert(orig >= 1 and orig <= 9, "default chaos should be 1-9")
	assert(oracle.set_chaos(7) == true)
	assert_eq(oracle.get_chaos(), 7)
	assert(oracle.set_chaos(0) == false, "chaos 0 should be rejected")
	assert_eq(oracle.get_chaos(), 7, "chaos should remain 7")
	assert(oracle.set_chaos(10) == false, "chaos 10 should be rejected")
	oracle.set_chaos(orig)
end)

print()
print(string.format("Results: %d passed, %d failed, %d total", passed, failed, passed + failed))
if failed > 0 then
	os.exit(1)
end
