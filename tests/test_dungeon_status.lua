#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.commands.dungeon_status")

local passed, failed = 0, 0

print("Testing dungeon status functions:")
print("==================================")

local function check(name, got, expected)
	if got == expected then
		print("PASS " .. name)
		passed = passed + 1
	else
		print(string.format("FAIL %s: got %s, expected %s", name, tostring(got), tostring(expected)))
		failed = failed + 1
	end
end

-- ============================================================
-- collect_room_tags
-- ============================================================

do
	local lines = { "[R:1|cleared]" }
	local tags = M.collect_room_tags(lines)
	check("collect: single room", #tags, 1)
	if #tags >= 1 then
		check("collect: single room id", tags[1].id, "1")
		check("collect: single room raw", tags[1].raw, "[R:1|cleared]")
	end
end

do
	local lines = { "[R:3|active]", "[R:1|cleared]", "[R:2|unexplored]" }
	local tags = M.collect_room_tags(lines)
	check("collect: sorted by id", #tags, 3)
	if #tags >= 3 then
		check("collect: order 1", tags[1].id, "1")
		check("collect: order 2", tags[2].id, "2")
		check("collect: order 3", tags[3].id, "3")
	end
end

do
	local lines = {
		"[R:1|cleared]",
		"[R:1|cleared,looted|entry cave]",
	}
	local tags = M.collect_room_tags(lines)
	check("collect: duplicate id keeps last", #tags, 1)
	if #tags >= 1 then
		check("collect: last wins raw", tags[1].raw, "[R:1|cleared,looted|entry cave]")
	end
end

do
	local lines = { "just some text", "no room tags here" }
	local tags = M.collect_room_tags(lines)
	check("collect: no rooms", #tags, 0)
end

do
	local lines = {
		"[#R:1]",
	}
	local tags = M.collect_room_tags(lines)
	check("collect: ignores [#R:...] references", #tags, 0)
end

do
	local lines = {
		"[N:Jonah|friendly]",
		"[PC:Kael|HP 8]",
		"[F:Jefe|HP 12]",
		"[R:5|active]",
	}
	local tags = M.collect_room_tags(lines)
	check("collect: ignores other tag types", #tags, 1)
	if #tags >= 1 then
		check("collect: only R picked up", tags[1].id, "5")
	end
end

do
	local lines = { "d: hit -> [R:3|active] [F:Guard|HP 5]" }
	local tags = M.collect_room_tags(lines)
	check("collect: room mixed with other tags on same line", #tags, 1)
	if #tags >= 1 then
		check("collect: extracted from mixed line", tags[1].id, "3")
	end
end

do
	local lines = { "[R:1|cleared]", "[R:2|active]", "[R:10|unexplored]" }
	local tags = M.collect_room_tags(lines)
	check("collect: numeric sort 1,2,10", #tags, 3)
	if #tags >= 3 then
		check("collect: first id", tags[1].id, "1")
		check("collect: middle id", tags[2].id, "2")
		check("collect: last id (10 > 2)", tags[3].id, "10")
	end
end

do
	local lines = { "[R:A|lobby]", "[R:B|kitchen]" }
	local tags = M.collect_room_tags(lines)
	check("collect: alphanumeric ids", #tags, 2)
	if #tags >= 2 then
		check("collect: alphanumeric sort A", tags[1].id, "A")
		check("collect: alphanumeric sort B", tags[2].id, "B")
	end
end

-- ============================================================
-- find_existing_block
-- ============================================================

do
	local lines = { "no block here", "just text" }
	local s, e = M.find_existing_block(lines)
	check("find: no block", s == nil and e == nil, true)
end

do
	local lines = {
		"=== Dungeon Status ===",
		"[R:1|cleared]",
		"[R:2|active]",
	}
	local s, e = M.find_existing_block(lines)
	check("find: block exists", s ~= nil, true)
	if s then
		check("find: header at line 1", s, 1)
		check("find: last content at line 3", e, 3)
	end
end

do
	local lines = {
		"text",
		"=== Dungeon Status ===",
		"[R:1|cleared]",
		"=== Session 5 ===",
	}
	local s, e = M.find_existing_block(lines)
	check("find: block before next section", s ~= nil, true)
	if s then
		check("find: header at line 2", s, 2)
		check("find: content until before ===", e, 3)
	end
end

do
	local lines = {
		"=== Dungeon Status ===",
		"=== Session 5 ===",
	}
	local s, e = M.find_existing_block(lines)
	check("find: empty block followed by section", s ~= nil, true)
	if s then
		check("find: header at line 1", s, 1)
		check("find: no content, header is end", e, 1)
	end
end

do
	local lines = { "=== Dungeon Status ===" }
	local s, e = M.find_existing_block(lines)
	check("find: block at EOF", s ~= nil, true)
	if s then
		check("find: header at line 1", s, 1)
		check("find: eof no content", e, 1)
	end
end

-- ============================================================
-- build_status_block
-- ============================================================

do
	local tags = { { id = "1", raw = "[R:1|cleared]" } }
	local lines = M.build_status_block(tags)
	check("build: single tag", #lines, 2)
	if #lines >= 2 then
		check("build: header", lines[1], "=== Dungeon Status ===")
		check("build: tag line", lines[2], "[R:1|cleared]")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|looted|entry cave]" },
		{ id = "2", raw = "[R:2|active|barracks]" },
	}
	local lines = M.build_status_block(tags)
	check("build: multiple tags", #lines, 3)
	if #lines >= 3 then
		check("build: header", lines[1], "=== Dungeon Status ===")
		check("build: first tag", lines[2], "[R:1|cleared|looted|entry cave]")
		check("build: second tag", lines[3], "[R:2|active|barracks]")
	end
end

do
	local tags = {}
	local lines = M.build_status_block(tags)
	check("build: empty tags", #lines, 1)
	if #lines >= 1 then
		check("build: only header", lines[1], "=== Dungeon Status ===")
	end
end

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
	os.exit(1)
end
