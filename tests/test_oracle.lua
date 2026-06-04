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

print("roll_history:")
test("get_history returns empty for unknown buffer", function()
	local h = oracle.get_history(9999)
	assert_eq(type(h), "table", "should be a table")
	assert_eq(#h, 0, "should be empty")
end)

test("add_to_history then get_history returns entry", function()
	local result = { table = "fate", value = "yes", display = "Yes" }
	oracle.add_to_history(50, result, 15)
	local h = oracle.get_history(50)
	assert_eq(#h, 1, "should have 1 entry")
	assert_eq(h[1].line, 15, "line should match")
	assert_eq(h[1].bufnr, 50, "bufnr should match")
	assert_eq(h[1].result.value, "yes", "result value should match")
	oracle.clear_history(50)
end)

test("clear_history clears", function()
	oracle.add_to_history(60, { table = "binary", value = "yes" }, 5)
	oracle.clear_history(60)
	local h = oracle.get_history(60)
	assert_eq(#h, 0, "should be empty after clear")
end)

test("per-buffer isolation", function()
	oracle.add_to_history(1, { table = "fate", value = "yes" }, 1)
	oracle.add_to_history(1, { table = "fate", value = "no" }, 2)
	oracle.add_to_history(2, { table = "binary", value = "maybe" }, 3)

	local h1 = oracle.get_history(1)
	local h2 = oracle.get_history(2)

	assert_eq(#h1, 2, "buf 1 should have 2 entries")
	assert_eq(#h2, 1, "buf 2 should have 1 entry")
	assert_eq(h1[1].result.value, "yes")
	assert_eq(h1[2].result.value, "no")
	assert_eq(h2[1].result.value, "maybe")

	oracle.clear_history(1)
	oracle.clear_history(2)
end)

test("multiple entries preserve insertion order", function()
	oracle.add_to_history(70, { table = "fate", value = "yes" }, 1)
	oracle.add_to_history(70, { table = "fate", value = "no" }, 2)
	oracle.add_to_history(70, { table = "fate", value = "maybe" }, 3)

	local h = oracle.get_history(70)
	assert_eq(#h, 3)
	assert_eq(h[1].result.value, "yes")
	assert_eq(h[2].result.value, "no")
	assert_eq(h[3].result.value, "maybe")
	oracle.clear_history(70)
end)

test("nil bufnr defaults to 0", function()
	oracle.add_to_history(0, { table = "fate", value = "exceptional_yes" }, 5)
	local h = oracle.get_history(nil)
	assert_eq(#h, 1, "should find entry at bufnr 0")
	assert_eq(h[1].result.value, "exceptional_yes")
	oracle.clear_history(0)
end)

print("custom_tables:")
test("init with empty table is no-op", function()
	local before = #oracle.list_tables()
	oracle.init({})
	local after = #oracle.list_tables()
	assert_eq(after, before, "list_tables should not change with empty custom_tables")
end)

test("init array format creates equal weight entries", function()
	oracle.init({ test_equal = { "A", "B", "C" } })
	local tables = oracle.list_tables()
	local found = false
	for _, name in ipairs(tables) do
		if name == "Test_equal" then
			found = true
		end
	end
	assert(found, "custom table should appear in list_tables")
	local r = oracle.roll("test_equal")
	assert(r ~= nil, "roll should succeed")
	assert_eq(r.table, "test_equal")
	assert(r.value ~= nil, "should have a value")
end)

test("init dict format preserves weights", function()
	oracle.init({ test_weighted = { easy = 1, medium = 2, hard = 3 } })
	local tables = oracle.list_tables()
	local found = false
	for _, name in ipairs(tables) do
		if name == "Test_weighted" then
			found = true
		end
	end
	assert(found, "weighted table should appear in list_tables")
	local r = oracle.roll("test_weighted")
	assert(r ~= nil)
	assert_eq(r.table, "test_weighted")
end)

test("custom table roll returns one of the entries", function()
	oracle.init({ test_choices = { "X", "Y" } })
	local r = oracle.roll("test_choices")
	assert(r.value == "X" or r.value == "Y", "should be one of the choices")
	assert(r.display ~= nil, "should have display string")
end)

test("custom table overrides built-in table", function()
	oracle.init({ binary = { only_yes = 1 } })
	local r = oracle.roll("binary")
	assert_eq(r.value, "only_yes", "custom binary should override built-in")
end)

test("entry with weight 0 is excluded", function()
	oracle.init({ test_zero = { A = 1, B = 0 } })
	local r = oracle.roll("test_zero")
	assert_eq(r.value, "A", "only A should be rolled (B has weight 0)")
end)

test("single-entry table always returns that entry", function()
	oracle.init({ test_single = { "Only" } })
	for _ = 1, 10 do
		local r = oracle.roll("test_single")
		assert_eq(r.value, "Only", "single entry should always be returned")
	end
end)

test("mixed-case table name resolved case-insensitively", function()
	oracle.init({ Weather = { "Sunny", "Rain" } })
	local r = oracle.roll("weather")
	assert(r.value == "Sunny" or r.value == "Rain", "lowercase roll should find Weather table")
end)

print()
print(string.format("Results: %d passed, %d failed, %d total", passed, failed, passed + failed))
if failed > 0 then
	os.exit(1)
end
