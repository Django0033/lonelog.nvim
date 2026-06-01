#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.addons.dungeon.dungeon_status")

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
		"===",
	}
	local s, e = M.find_existing_block(lines)
	check("find: block exists", s ~= nil, true)
	if s then
		check("find: header at line 1", s, 1)
		check("find: closing at line 4", e, 4)
	end
end

do
	local lines = {
		"text",
		"=== Dungeon Status ===",
		"[R:1|cleared]",
		"===",
		"=== Session 5 ===",
	}
	local s, e = M.find_existing_block(lines)
	check("find: block before next section", s ~= nil, true)
	if s then
		check("find: header at line 2", s, 2)
		check("find: closing at line 4", e, 4)
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
	check("build: single tag count", #lines, 5)
	if #lines >= 5 then
		check("build: header", lines[1], "=== Dungeon Status ===")
		check("build: tag line", lines[2], "[R:1|cleared]")
		check("build: map header", lines[3], "--- Map ---")
		check("build: map line", lines[4], "R1")
		check("build: closing", lines[5], "===")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared,looted|entry cave]" },
		{ id = "2", raw = "[R:2|active|barracks]" },
	}
	local lines = M.build_status_block(tags)
	check("build: multiple tags count", #lines, 7)
	if #lines >= 7 then
		check("build: header", lines[1], "=== Dungeon Status ===")
		check("build: first tag", lines[2], "[R:1|cleared,looted|entry cave]")
		check("build: second tag", lines[3], "[R:2|active|barracks]")
		check("build: map header", lines[4], "--- Map ---")
		check("build: map r1", lines[5], "R1 (entry cave)")
		check("build: map r2", lines[6], "R2 (barracks)")
		check("build: closing", lines[7], "===")
	end
end

do
	local tags = {}
	local lines = M.build_status_block(tags)
	check("build: empty tags", #lines, 2)
	if #lines >= 2 then
		check("build: only header", lines[1], "=== Dungeon Status ===")
		check("build: closing", lines[2], "===")
	end
end

-- ============================================================
-- find_frontmatter_end
-- ============================================================

do
	local lines = { "some text", "no frontmatter" }
	local n = M.find_frontmatter_end(lines)
	check("frontmatter: no frontmatter returns 0", n, 0)
end

do
	local lines = {
		"---",
		"campaign: test",
		"---",
		"[R:1|cleared]",
	}
	local n = M.find_frontmatter_end(lines)
	check("frontmatter: returns closing --- line number", n, 3)
end

do
	local lines = {
		"---",
		"campaign: test",
		"date: 2024-01-01",
		"---",
		"",
		"# Session 1",
	}
	local n = M.find_frontmatter_end(lines)
	check("frontmatter: multi-line yaml", n, 4)
end

do
	local lines = {
		"---",
		"opened but never closed",
	}
	local n = M.find_frontmatter_end(lines)
	check("frontmatter: unclosed returns 0", n, 0)
end

-- ============================================================
-- get_room_info
-- ============================================================

do
	local tags = { { id = "3", raw = "[R:3|active|almacen|exits N:R1, S:R2]" } }
	local info = M.get_room_info(tags)
	check("info: id lookup", info["3"] ~= nil, true)
	if info["3"] then
		check("info: desc", info["3"].desc, "almacen")
		if info["3"].exits then
			check("info: exits count", #info["3"].exits, 2)
		end
	end
end

do
	local tags = { { id = "1", raw = "[R:1|cleared]" } }
	local info = M.get_room_info(tags)
	check("info: minimal no desc", info["1"].desc, nil)
	check("info: minimal no exits", info["1"].exits, nil)
end

do
	local tags = { { id = "5", raw = "[R:5|trapped|exits N:R10|HP 5]" } }
	local info = M.get_room_info(tags)
	check("info: exits not last field has exits", info["5"].exits ~= nil, true)
	check("info: exits non-last desc nil", info["5"].desc, nil)
	if info["5"].exits then
		check("info: exits non-last count", #info["5"].exits, 1)
	end
end

-- ============================================================
-- build_ascii_map
-- ============================================================

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|entry cave|exits N:R3]" },
		{ id = "3", raw = "[R:3|cleared|armory|exits E:R4]" },
		{ id = "4", raw = "[R:4|unexplored|storage]" },
	}
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: linear chain count", #map, 2)
	if #map >= 2 then
		check("map: linear header", map[1], "--- Map ---")
		check("map: linear forward", map[2], "R1 (entry cave) --N--> R3 (armory) --E--> R4 (storage)")
	end
end

do
	local tags = { { id = "2", raw = "[R:2|active|barracks]" } }
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: isolated count", #map, 2)
	if #map >= 2 then
		check("map: isolated header", map[1], "--- Map ---")
		check("map: isolated line", map[2], "R2 (barracks)")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|entry cave|exits N:R3]" },
		{ id = "3", raw = "[R:3|cleared|armory|exits S:R1]" },
	}
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: bidirectional count", #map, 3)
	if #map >= 3 then
		check("map: bidirectional forward", map[2], "R1 (entry cave) --N--> R3 (armory)")
		check("map: bidirectional back-ref", map[3], "R3 <--S-- R1 (entry cave)")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|entry cave|exits N:R99]" },
	}
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: missing dest count", #map, 2)
	if #map >= 2 then
		check("map: missing dest line", map[2], "R1 (entry cave) --N--> R99 (??? not found)")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|entry cave|exits N:R3, S:R2]" },
		{ id = "2", raw = "[R:2|active|barracks]" },
		{ id = "3", raw = "[R:3|cleared|armory]" },
	}
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: branching count", #map, 3)
	if #map >= 3 then
		check("map: branching branch", map[2], "R1 (entry cave) --S--> R2 (barracks)")
		check("map: branching chain", map[3], "R1 (entry cave) --N--> R3 (armory)")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|entry cave|exits N:R3]" },
		{ id = "2", raw = "[R:2|active|barracks]" },
		{ id = "3", raw = "[R:3|cleared|armory|exits S:R1, E:R4]" },
		{ id = "4", raw = "[R:4|unexplored|storage|exits W:R3]" },
	}
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: mixed count", #map, 5)
	if #map >= 5 then
		check("map: mixed header", map[1], "--- Map ---")
		check("map: mixed r1 forward", map[2], "R1 (entry cave) --N--> R3 (armory) --E--> R4 (storage)")
		check("map: mixed r2 isolated", map[3], "R2 (barracks)")
		check("map: mixed back-ref 1", map[4], "R3 <--S-- R1 (entry cave)")
		check("map: mixed back-ref 2", map[5], "R4 <--W-- R3 (armory)")
	end
end

do
	local tags = {}
	local info = M.get_room_info(tags)
	local map = M.build_ascii_map(tags, info)
	check("map: empty tags", #map, 0)
end

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
	os.exit(1)
end
