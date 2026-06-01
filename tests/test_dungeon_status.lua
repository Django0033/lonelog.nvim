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
	check("build: single tag", #lines, 3)
	if #lines >= 3 then
		check("build: header", lines[1], "=== Dungeon Status ===")
		check("build: tag line", lines[2], "[R:1|cleared]")
		check("build: closing", lines[3], "===")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|looted|entry cave]" },
		{ id = "2", raw = "[R:2|active|barracks]" },
	}
	local lines = M.build_status_block(tags)
	check("build: multiple tags", #lines, 4)
	if #lines >= 4 then
		check("build: header", lines[1], "=== Dungeon Status ===")
		check("build: first tag", lines[2], "[R:1|cleared|looted|entry cave]")
		check("build: second tag", lines[3], "[R:2|active|barracks]")
		check("build: closing", lines[4], "===")
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
-- parse_tag_info
-- ============================================================

do
	local info = M.parse_tag_info("[R:3|active|almacen|exits N:R1, S:R2]")
	check("parse: basic id", info.id, "3")
	check("parse: basic desc", info.desc, "almacen")
	if info.exits then
		check("parse: exits count", #info.exits, 2)
		if #info.exits >= 2 then
			check("parse: exit 1 dir", info.exits[1].dir, "N")
			check("parse: exit 1 id", info.exits[1].id, "1")
			check("parse: exit 2 dir", info.exits[2].dir, "S")
			check("parse: exit 2 id", info.exits[2].id, "2")
		end
	end
end

do
	local info = M.parse_tag_info("[R:1|cleared]")
	check("parse: no desc or exits id", info.id, "1")
	check("parse: no desc", info.desc, nil)
	check("parse: no exits", info.exits, nil)
end

do
	local info = M.parse_tag_info("[R:5|trapped|exits N:R10|HP 5]")
	check("parse: exits not last field id", info.id, "5")
	if info.exits then
		check("parse: exits non-last count", #info.exits, 1)
		if #info.exits >= 1 then
			check("parse: exit dir non-last", info.exits[1].dir, "N")
			check("parse: exit id non-last", info.exits[1].id, "10")
		end
	end
end

do
	local info = M.parse_tag_info("[R:3|active|exits NE:R1, SW:R2]")
	check("parse: compound dirs id", info.id, "3")
	check("parse: compound dirs desc nil", info.desc, nil)
	if info.exits then
		check("parse: compound dirs count", #info.exits, 2)
		if #info.exits >= 2 then
			check("parse: NE dir", info.exits[1].dir, "NE")
			check("parse: SW dir", info.exits[2].dir, "SW")
		end
	end
end

-- ============================================================
-- build_annotation
-- ============================================================

do
	local raw = "[R:3|active|almacen|exits N:R1, S:R2]"
	local desc_by_id = { ["1"] = "entry cave", ["2"] = "barracks" }
	local annotation = M.build_annotation(raw, desc_by_id)
	check("annot: basic", annotation, "  → N → R1 (entry cave) │ S → R2 (barracks)")
end

do
	local raw = "[R:2|active|barracks]"
	local annotation = M.build_annotation(raw, {})
	check("annot: no exits", annotation, "")
end

do
	local raw = "[R:3|active|exits N:R5]"
	local annotation = M.build_annotation(raw, {})
	check("annot: dest not found", annotation, "  → N → R5 (?)")
end

do
	local raw = "[R:1|cleared|entry cave|exits N:R2, E:R3, W:R4]"
	local desc_by_id = { ["2"] = "barracks", ["3"] = "armory", ["4"] = "storage" }
	local annotation = M.build_annotation(raw, desc_by_id)
	check("annot: three exits", annotation, "  → N → R2 (barracks) │ E → R3 (armory) │ W → R4 (storage)")
end

-- ============================================================
-- build_status_block (with annotations)
-- ============================================================

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared|entry cave|exits N:R3]" },
		{ id = "2", raw = "[R:2|active|barracks]" },
		{ id = "3", raw = "[R:3|cleared|armory|exits S:R1]" },
	}
	local lines = M.build_status_block(tags)
	check("build: annotated count", #lines, 5)
	if #lines >= 5 then
		check("build: annotated header", lines[1], "=== Dungeon Status ===")
		check("build: annotated r1", lines[2], "[R:1|cleared|entry cave|exits N:R3]  → N → R3 (armory)")
		check("build: annotated r2", lines[3], "[R:2|active|barracks]")
		check("build: annotated r3", lines[4], "[R:3|cleared|armory|exits S:R1]  → S → R1 (entry cave)")
		check("build: annotated closing", lines[5], "===")
	end
end

do
	local tags = {
		{ id = "1", raw = "[R:1|cleared]" },
		{ id = "2", raw = "[R:2|active]" },
	}
	local lines = M.build_status_block(tags)
	check("build: no exits unchanged", #lines, 4)
	if #lines >= 4 then
		check("build: no exits line 1", lines[2], "[R:1|cleared]")
		check("build: no exits line 2", lines[3], "[R:2|active]")
	end
end

do
	local tags = {}
	local lines = M.build_status_block(tags)
	check("build: empty no annotation issues", #lines, 2)
end

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
	os.exit(1)
end
