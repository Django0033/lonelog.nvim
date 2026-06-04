#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.addons.dungeon.room_state")

local passed, failed = 0, 0

print("Testing room state functions:")
print("==============================")

local function check(name, got, expected)
	if got == expected then
		print("PASS " .. name)
		passed = passed + 1
	else
		local g = type(got) == "table" and "table" or tostring(got)
		local e = type(expected) == "table" and "table" or tostring(expected)
		print(string.format("FAIL %s: got %s, expected %s", name, g, e))
		failed = failed + 1
	end
end

local function check_table(name, got, expected)
	local ok = type(got) == "table" and type(expected) == "table" and #got == #expected
	if ok then
		for i = 1, #got do
			if got[i] ~= expected[i] then
				ok = false
				break
			end
		end
	end
	if ok then
		print("PASS " .. name)
		passed = passed + 1
	else
		print("FAIL " .. name)
		failed = failed + 1
	end
end

-- ============================================================
-- parse_states
-- ============================================================

do
	local states = M.parse_states("[R:3|cleared,looted|almacen]")
	check_table("parse: two states", states, { "cleared", "looted" })
end

do
	local states = M.parse_states("[R:1|active]")
	check_table("parse: single state", states, { "active" })
end

do
	local states = M.parse_states("[R:4||barracks]")
	check_table("parse: empty state defaults to unexplored", states, { "unexplored" })
end

do
	local states = M.parse_states("[R:5]")
	check_table("parse: no pipe after ID defaults to unexplored", states, { "unexplored" })
end

do
	local states = M.parse_states("[R:2|cleared,looted,locked,trapped|cavern]")
	check_table("parse: four states", states, { "cleared", "looted", "locked", "trapped" })
end

do
	local states = M.parse_states("[R:3|cleared,looted|almacen|exits N:R1]")
	check_table("parse: with exits field", states, { "cleared", "looted" })
end

-- ============================================================
-- build_tag
-- ============================================================

do
	local tag = M.build_tag("[R:3|cleared,looted|almacen]", { "active" })
	check("build: single state", tag, "[R:3|active|almacen]")
end

do
	local tag = M.build_tag("[R:3|cleared|almacen]", { "cleared", "looted" })
	check("build: add state", tag, "[R:3|cleared,looted|almacen]")
end

do
	local tag = M.build_tag("[R:3|cleared,looted|almacen|exits N:R1]", { "trapped", "locked" })
	check("build: preserves exits", tag, "[R:3|trapped,locked|almacen|exits N:R1]")
end

do
	local tag = M.build_tag("[R:1|cleared]", {})
	check("build: empty states defaults to unexplored", tag, "[R:1|unexplored]")
end

do
	local tag = M.build_tag("[R:1|cleared|looted|room]", {})
	check("build: empty states with extra pipes", tag, "[R:1|unexplored|looted|room]")
end

do
	local tag = M.build_tag("[R:3|unexplored|entrance]", { "cleared", "looted", "safe" })
	check("build: three states", tag, "[R:3|cleared,looted,safe|entrance]")
end

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
	os.exit(1)
end
