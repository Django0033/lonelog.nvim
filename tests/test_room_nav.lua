#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.addons.dungeon.room_nav")

local passed, failed = 0, 0

print("Testing room navigation functions:")
print("====================================")

local function check(name, got, expected)
	if got == expected then
		print("PASS " .. name)
		passed = passed + 1
	else
		print(string.format("FAIL %s: got %s, expected %s", name, tostring(got), tostring(expected)))
		failed = failed + 1
	end
end

local function check_table(name, got, expected)
	local ok
	if type(got) == "table" and type(expected) == "table" then
		ok = #got == #expected
		if ok then
			for i = 1, #got do
				if got[i].dir ~= expected[i].dir or got[i].id ~= expected[i].id then
					ok = false
					break
				end
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
-- parse_exits
-- ============================================================

do
	local result = M.parse_exits("[R:3|active|almacen|exits N:R1, S:R2]")
	check_table("parse_exits: basic", result, {
		{ dir = "N", id = "1" },
		{ dir = "S", id = "2" },
	})
end

do
	local result = M.parse_exits("[R:1|cleared|exits E:R2, W:R3, N:R4]")
	check_table("parse_exits: three exits", result, {
		{ dir = "E", id = "2" },
		{ dir = "W", id = "3" },
		{ dir = "N", id = "4" },
	})
end

do
	local result = M.parse_exits("[R:5|trapped|exits N:R10]")
	check_table("parse_exits: double digit id", result, {
		{ dir = "N", id = "10" },
	})
end

do
	local result = M.parse_exits("[R:1|cleared]")
	check("parse_exits: no exits field", #result, 0)
end

do
	local result = M.parse_exits("no tag here")
	check("parse_exits: not a tag", #result, 0)
end

do
	local result = M.parse_exits("")
	check("parse_exits: empty string", #result, 0)
end

do
	local result = M.parse_exits("[R:A|lobby|exits S:RB]")
	check_table("parse_exits: alphanumeric ids", result, {
		{ dir = "S", id = "B" },
	})
end

do
	local result = M.parse_exits("[R:3|active|exits NE:R1, SW:R2, UP:R5]")
	check_table("parse_exits: compound directions", result, {
		{ dir = "NE", id = "1" },
		{ dir = "SW", id = "2" },
		{ dir = "UP", id = "5" },
	})
end

do
	local result = M.parse_exits("[R:2|active|exits N:R3, S:R4|HP 5]")
	check_table("parse_exits: exits not last field", result, {
		{ dir = "N", id = "3" },
		{ dir = "S", id = "4" },
	})
end

do
	local result = M.parse_exits("[R:1|cleared|exits N:R2, N:R3]")
	check_table("parse_exits: multiple same direction", result, {
		{ dir = "N", id = "2" },
		{ dir = "N", id = "3" },
	})
end

-- ============================================================
-- find_room_tag_on_line
-- ============================================================

do
	local raw = M.find_room_tag_on_line("text [R:3|active|almacen] more text")
	check("find: basic room tag", raw, "[R:3|active|almacen]")
end

do
	local raw = M.find_room_tag_on_line("no room here")
	check("find: no room tag", raw, nil)
end

do
	local raw = M.find_room_tag_on_line("d: hit -> [R:3|active] [F:Guard|HP 5]")
	check("find: mixed with other tags", raw, "[R:3|active]")
end

do
	local raw = M.find_room_tag_on_line("")
	check("find: empty line", raw, nil)
end

do
	local raw = M.find_room_tag_on_line("[N:Jonah|friendly]")
	check("find: other tag type", raw, nil)
end

-- ============================================================
-- collect_room_data
-- ============================================================

do
	local lines = {
		"[R:1|cleared|entry cave]",
		"[R:2|active|barracks|exits N:R1, S:R3]",
		"[R:3|unexplored]",
	}
	local rooms = M.collect_room_data(lines)
	local count = 0
	for _ in pairs(rooms) do count = count + 1 end
	check("collect: count", count, 3)
	if rooms["1"] then
		check("collect: room 1 line", rooms["1"].line, 1)
		check("collect: room 1 raw", rooms["1"].raw, "[R:1|cleared|entry cave]")
	end
	if rooms["2"] then
		check("collect: room 2 exits count", #rooms["2"].exits, 2)
	end
	if rooms["3"] then
		check("collect: room 3 no exits", #rooms["3"].exits, 0)
	end
end

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
	os.exit(1)
end
