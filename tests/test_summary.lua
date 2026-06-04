#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

-- Global vim mock for parse_all_sessions
_G.vim = {
	api = {
		nvim_buf_get_lines = function(bufnr, start, ending, strict)
			return {
				"## Session 1",
				"2026-05-31",
				"",
				"### Recap",
				"- Something happened",
				"",
				"### Goals",
				"- Find the artifact",
				"",
				"### S1 *Dungeon entrance*",
				"@ Look around",
				"? Is anyone here?",
				"d: 2d6+3[4, 2] = 10",
				" -> There is a guard",
				"=> Fight!",
				"[N:Guard|hostile]",
				"",
				"(note: first encounter)",
				"",
				"## Session 2",
				"2026-06-01",
				"",
				"### S1 *Deep in the dungeon*",
				"@ Sneak past guard",
				"PC: \"I'll try\"",
				"d: 2d20kh1[15, 8] = 15",
				"tbl: Encounters (d6)",
				"[L:Dungeon|dark]",
				"[E:Torch 2/6]",
			}
		end,
		nvim_get_current_buf = function()
			return 1
		end,
	},
	notify = function(msg, level) end,
	trim = function(s)
		return s:match("^%s*(.-)%s*$") or s
	end,
}

local passed = 0
local failed = 0

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		io.write("  PASS " .. name .. "\n")
		passed = passed + 1
	else
		io.write("  FAIL " .. name .. "\n")
		io.write("    " .. tostring(err) .. "\n")
		failed = failed + 1
	end
end

local function assert_eq(actual, expected, msg)
	if actual ~= expected then
		error((msg or "assertion failed") .. ": got " .. tostring(actual) .. ", expected " .. tostring(expected))
	end
end

local summary = require("lonelog.commands.summary")

-- ============================================================================
-- parse_all_sessions
-- ============================================================================

print("\n=== parse_all_sessions ===\n")

test("parse_all_sessions finds multiple sessions", function()
	local sessions = summary.parse_all_sessions(0)
	assert_eq(#sessions, 2, "should find 2 sessions")
end)

test("parse_all_sessions session 1 has correct number and date", function()
	local sessions = summary.parse_all_sessions(0)
	local s1 = sessions[1]
	assert_eq(s1.number, 1, "session 1 number should be 1")
	assert_eq(s1.date, "2026-05-31", "session 1 date should be 2026-05-31")
end)

test("parse_all_sessions session 2 has correct number and date", function()
	local sessions = summary.parse_all_sessions(0)
	local s2 = sessions[2]
	assert_eq(s2.number, 2, "session 2 number should be 2")
	assert_eq(s2.date, "2026-06-01", "session 2 date should be 2026-06-01")
end)

test("parse_all_sessions session boundaries correct", function()
	local sessions = summary.parse_all_sessions(0)
	assert_eq(sessions[1].start_line, 1, "session 1 starts at line 1")
	assert_eq(sessions[1].end_line, 20, "session 1 ends before session 2 (line 20)")
	assert_eq(sessions[2].start_line, 20, "session 2 starts at line 20")
	assert_eq(sessions[2].end_line, 30, "session 2 ends at EOF (line 30)")
end)

-- ============================================================================
-- build_session_summary
-- ============================================================================

print("\n=== build_session_summary ===\n")

local all_lines = {
	"## Session 1",
	"2026-05-31",
	"",
	"### Recap",
	"- Something happened",
	"",
	"### Goals",
	"- Find the artifact",
	"",
	"### S1 *Dungeon entrance*",
	"@ Look around",
	"? Is anyone here?",
	"d: 2d6+3[4, 2] = 10",
	" -> There is a guard",
	"=> Fight!",
	"[N:Guard|hostile]",
	"",
	"(note: first encounter)",
	"",
	"## Session 2",
	"2026-06-01",
	"",
	"### S1 *Deep in the dungeon*",
	"@ Sneak past guard",
	"PC: \"I'll try\"",
	"d: 2d20kh1[15, 8] = 15",
	"tbl: Encounters (d6)",
	"[L:Dungeon|dark]",
	"[E:Torch 2/6]",
}

local mock_scenes = {
	{ scene_id = "S1", context = "Dungeon entrance", type = "main", line = 10 },
	{ scene_id = "S1", context = "Deep in the dungeon", type = "main", line = 22 },
}

local mock_tags = {
	{ type = "N", name = "Guard", line = 16 },
	{ type = "L", name = "Dungeon", line = 26 },
	{ type = "E", name = "Torch", line = 27 },
}

local session1 = { number = 1, date = "2026-05-31", start_line = 1, end_line = 20 }
local session2 = { number = 2, date = "2026-06-01", start_line = 20, end_line = 30 }

test("build_session_summary session 1 basic counts", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	assert_eq(s.lines_count, 19, "session 1 should have 19 lines")
	assert(s.words_count > 0, "session 1 should have words")
end)

test("build_session_summary session 1 notation counts", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local n = s.notation
	assert_eq(n.actions, 1, "session 1 should have 1 action")
	assert_eq(n.questions, 1, "session 1 should have 1 question")
	assert_eq(n.dice_lines, 1, "session 1 should have 1 dice line")
	assert_eq(n.arrows, 1, "session 1 should have 1 arrow")
	assert_eq(n.consequences, 1, "session 1 should have 1 consequence")
end)

test("build_session_summary session 1 prose counts", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	assert_eq(s.meta_notes, 1, "session 1 should have 1 meta note (from prose parser)")
	assert_eq(s.narrative_blocks, 0, "session 1 should have 0 narrative blocks")
end)

test("build_session_summary session 1 filtered tags", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	assert_eq(#s.tags, 1, "session 1 should have 1 tag (Guard on line 16)")
	assert_eq(s.tags[1].name, "Guard", "session 1 tag should be Guard")
end)

test("build_session_summary session 1 filtered scenes", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	assert_eq(#s.scenes, 1, "session 1 should have 1 scene")
	assert_eq(s.scenes[1].context, "Dungeon entrance", "session 1 scene context")
end)

test("build_session_summary session 1 dice summary", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	assert_eq(s.dice.count, 1, "session 1 should have 1 dice roll")
	assert_eq(s.dice.sum, 10, "session 1 dice sum should be 10")
	assert_eq(s.dice.average, 10, "session 1 dice average should be 10")
end)

test("build_session_summary session 2 notation counts", function()
	local s = summary.build_session_summary(session2, all_lines, mock_tags, mock_scenes)
	local n = s.notation
	assert_eq(n.actions, 1, "session 2 should have 1 action")
	assert_eq(n.dice_lines, 1, "session 2 should have 1 dice line")
	assert_eq(n.table_rolls, 1, "session 2 should have 1 table roll")
	assert_eq(n.questions, 0, "session 2 should have 0 questions")
end)

test("build_session_summary session 2 prose counts", function()
	local s = summary.build_session_summary(session2, all_lines, mock_tags, mock_scenes)
	assert_eq(s.dialogues, 1, "session 2 should have 1 dialogue (from prose parser)")
end)

test("build_session_summary session 2 filtered tags", function()
	local s = summary.build_session_summary(session2, all_lines, mock_tags, mock_scenes)
	assert_eq(#s.tags, 2, "session 2 should have 2 tags (Dungeon, Torch)")
	assert_eq(s.tags[1].name, "Dungeon", "session 2 first tag should be Dungeon")
	assert_eq(s.tags[2].name, "Torch", "session 2 second tag should be Torch")
end)

test("build_session_summary session 2 dice summary", function()
	local s = summary.build_session_summary(session2, all_lines, mock_tags, mock_scenes)
	assert_eq(s.dice.count, 1, "session 2 should have 1 dice roll")
	assert_eq(s.dice.sum, 15, "session 2 dice sum should be 15")
	assert_eq(s.dice.average, 15, "session 2 dice average should be 15")
end)

test("build_session_summary session 2 progress found", function()
	local s = summary.build_session_summary(session2, all_lines, mock_tags, mock_scenes)
	assert_eq(s.progress.clocks, 1, "session 2 should have 1 clock")
	assert_eq(s.progress.tracks, 0, "session 2 should have 0 tracks")
	assert_eq(s.progress.timers, 0, "session 2 should have 0 timers")
end)

-- ============================================================================
-- format_summary
-- ============================================================================

print("\n=== format_summary ===\n")

test("format_summary includes session number", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local lines = summary.format_summary(s)
	local found = false
	for _, l in ipairs(lines) do
		if l:match("Session 1") then
			found = true
			break
		end
	end
	assert(found, "format should include 'Session 1'")
end)

test("format_summary includes tag counts", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local lines = summary.format_summary(s)
	local found = false
	for _, l in ipairs(lines) do
		if l:match("NPC") and l:match("1") then
			found = true
			break
		end
	end
	assert(found, "format should include NPC count")
end)

test("format_summary includes scenes", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local lines = summary.format_summary(s)
	local found = false
	for _, l in ipairs(lines) do
		if l:match("S1") then
			found = true
			break
		end
	end
	assert(found, "format should include S1")
end)

test("format_summary includes prose count lines", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local lines = summary.format_summary(s)
	local found_notes = false
	local found_narrative = false
	for _, l in ipairs(lines) do
		if l:match("Notes") and l:match("%d") then
			found_notes = true
		end
		if l:match("Narrative") and l:match("%d") then
			found_narrative = true
		end
	end
	assert(found_notes, "format should include Notes count")
	assert(found_narrative, "format should include Narrative count")
end)

test("format_summary includes dice info when rolls present", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local lines = summary.format_summary(s)
	local found_avg = false
	for _, l in ipairs(lines) do
		if l:match("Average") then
			found_avg = true
			break
		end
	end
	assert(found_avg, "format should include dice average")
end)

-- ============================================================================
-- export_summary
-- ============================================================================

print("\n=== export_summary ===\n")

test("export_summary produces markdown with session number", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local text = summary.export_summary(s)
	assert(text:match("# Session 1 Summary"), "export should have heading")
	assert(text:match("%*%*Date:%*%* 2026%-05%-31"), "export should have date")
end)

test("export_summary includes table with scenes and tags", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local text = summary.export_summary(s)
	assert(text:match("| Actions"), "export should have actions row")
	assert(text:match("| Oracle"), "export should have oracle row")
	assert(text:match("| Meta notes"), "export should have meta notes row")
	assert(text:match("| Narrative"), "export should have narrative row")
end)

test("export_summary includes dice section when rolls present", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local text = summary.export_summary(s)
	assert(text:match("## Dice"), "export should have Dice section")
	assert(text:match("2d6%+3"), "export should include dice notation breakdown")
end)

test("export_summary includes Scenes section", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local text = summary.export_summary(s)
	assert(text:match("## Scenes"), "export should have Scenes section")
	assert(text:match("Dungeon entrance"), "export should include scene context")
end)

-- ============================================================================
-- Edge cases
-- ============================================================================

print("\n=== Edge cases ===\n")

test("parse_all_sessions with no sessions returns empty", function()
	_G.vim = {
		api = {
			nvim_buf_get_lines = function(bufnr, start, ending, strict)
				return {
					"# Random file",
					"",
					"Some text",
					"with no sessions",
				}
			end,
			nvim_get_current_buf = function()
				return 1
			end,
		},
		notify = function(msg, level) end,
		trim = function(s)
			return s:match("^%s*(.-)%s*$") or s
		end,
	}
	local sessions = require("lonelog.commands.summary").parse_all_sessions(0)
	assert_eq(#sessions, 0, "should find 0 sessions")
end)

test("build_session_summary with empty session", function()
	local empty_session = { number = 1, date = nil, start_line = 1, end_line = 2 }
	local empty_lines = { "## Session 1", "" }
	local s = summary.build_session_summary(empty_session, empty_lines, {}, {})
	assert_eq(s.lines_count, 1, "empty session should have 1 line (header only)")
	assert_eq(#s.tags, 0, "empty session should have 0 tags")
	assert_eq(#s.scenes, 0, "empty session should have 0 scenes")
	assert_eq(s.dice.count, 0, "empty session should have 0 dice rolls")
	assert_eq(s.meta_notes, 0, "empty session should have 0 meta notes")
	assert_eq(s.dialogues, 0, "empty session should have 0 dialogues")
	assert_eq(s.narrative_blocks, 0, "empty session should have 0 narrative blocks")
end)

test("session without date has nil date", function()
	_G.vim = {
		api = {
			nvim_buf_get_lines = function(bufnr, start, ending, strict)
				return {
					"## Session 1",
					"No date here",
					"some content",
				}
			end,
			nvim_get_current_buf = function()
				return 1
			end,
		},
		notify = function(msg, level) end,
		trim = function(s)
			return s:match("^%s*(.-)%s*$") or s
		end,
	}
	local sessions = require("lonelog.commands.summary").parse_all_sessions(0)
	assert_eq(#sessions, 1, "should find 1 session")
	assert_eq(sessions[1].date, nil, "date should be nil without YYYY-MM-DD")
end)

-- ============================================================================
-- roll_stats (Phase 3)
-- ============================================================================

print("\n=== roll_stats ===\n")

local mock_roll_stats = {
	by_type = {
		{ notation = "2d6", count = 2, sum = 17, min = 7, max = 10, average = 8.5 },
		{ notation = "1d20", count = 1, sum = 15, min = 15, max = 15, average = 15 },
	},
	total_rolls = 3,
	oracle_results = {
		{ table = "Fate Oracle", results = { Yes = 3, No = 1, ["Yes, but..."] = 2 } },
	},
}

test("build_session_summary with roll_stats includes by_type and total_rolls", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, mock_roll_stats)
	assert_eq(s.roll_stats.by_type[1].notation, "2d6", "first by_type should be 2d6")
	assert_eq(s.roll_stats.by_type[1].count, 2, "2d6 count should be 2")
	assert_eq(s.roll_stats.by_type[1].sum, 17, "2d6 sum should be 17")
	assert_eq(s.roll_stats.by_type[1].average, 8.5, "2d6 avg should be 8.5")
	assert_eq(s.roll_stats.by_type[1].min, 7, "2d6 min should be 7")
	assert_eq(s.roll_stats.by_type[1].max, 10, "2d6 max should be 10")
	assert_eq(s.roll_stats.by_type[2].notation, "1d20", "second by_type should be 1d20")
	assert_eq(s.roll_stats.total_rolls, 3, "total_rolls should be 3")
end)

test("build_session_summary with roll_stats includes oracle_results", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, mock_roll_stats)
	assert_eq(#s.roll_stats.oracle_results, 1, "should have 1 oracle table")
	assert_eq(s.roll_stats.oracle_results[1].table, "Fate Oracle", "oracle table name")
	assert_eq(s.roll_stats.oracle_results[1].results.Yes, 3, "Yes count should be 3")
	assert_eq(s.roll_stats.oracle_results[1].results.No, 1, "No count should be 1")
	assert_eq(s.roll_stats.oracle_results[1].results["Yes, but..."], 2, "Yes, but... count should be 2")
end)

test("build_session_summary without roll_stats has no roll_stats field", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	assert_eq(s.roll_stats, nil, "roll_stats should be nil when not provided")
end)

test("format_summary includes Dice by Type section with mock_roll_stats", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, mock_roll_stats)
	local lines = summary.format_summary(s)
	local found_header = false
	local found_2d6 = false
	for _, l in ipairs(lines) do
		if l:match("Dice by Type") then
			found_header = true
		end
		if l:match("2d6:") and l:match("2 rolls") and l:match("sum: 17") then
			found_2d6 = true
		end
	end
	assert(found_header, "format should include 'Dice by Type' section")
	assert(found_2d6, "format should include 2d6 breakdown with count, sum")
end)

test("format_summary without roll_stats has no Dice by Type section", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local lines = summary.format_summary(s)
	local found = false
	for _, l in ipairs(lines) do
		if l:match("Dice by Type") then
			found = true
			break
		end
	end
	assert(not found, "format should NOT include 'Dice by Type' when no roll_stats")
end)

test("export_summary includes Oracle Results section with roll_stats", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, mock_roll_stats)
	local text = summary.export_summary(s)
	assert(text:match("### Oracle Results"), "export should have 'Oracle Results' heading")
	assert(text:match("Fate Oracle:"), "export should have oracle table name")
	assert(text:match("Yes: 3"), "export should include Yes: 3")
	assert(text:match("No: 1"), "export should include No: 1")
	assert(text:match("Yes, but%.%.%."), "export should include 'Yes, but...'")
end)

test("export_summary without roll_stats has no Oracle Results section", function()
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes)
	local text = summary.export_summary(s)
	assert(not text:match("### Oracle Results"), "export should NOT have 'Oracle Results' when no roll_stats")
end)

-- Triangulation: edge cases
test("roll_stats with empty by_type does not error", function()
	local empty = { by_type = {}, total_rolls = 0, oracle_results = {} }
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, empty)
	assert_eq(s.roll_stats.total_rolls, 0, "total_rolls should be 0")
	assert_eq(#s.roll_stats.by_type, 0, "by_type should be empty")
	local lines = summary.format_summary(s)
	local found = false
	for _, l in ipairs(lines) do
		if l:match("Dice by Type") then found = true break end
	end
	assert(not found, "empty by_type should not show Dice by Type section")
end)

test("roll_stats with zero rolls does not add Oracle Results to export", function()
	local no_oracle = { by_type = {}, total_rolls = 0, oracle_results = {} }
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, no_oracle)
	local text = summary.export_summary(s)
	assert(not text:match("### Oracle Results"), "empty oracle_results should not show Oracle Results heading")
end)

test("roll_stats with multiple oracle tables shows each table", function()
	local multi_oracle = {
		by_type = {},
		total_rolls = 0,
		oracle_results = {
			{ table = "Fate", results = { Yes = 2, No = 1 } },
			{ table = "Mythic", results = { Yes = 4, ["No, but..."] = 1 } },
		},
	}
	local s = summary.build_session_summary(session1, all_lines, mock_tags, mock_scenes, nil, multi_oracle)
	assert_eq(#s.roll_stats.oracle_results, 2, "should have 2 oracle tables")
	local text = summary.export_summary(s)
	assert(text:match("Fate:"), "export should include Fate table")
	assert(text:match("Mythic:"), "export should include Mythic table")
	assert(text:match("No, but%.%.%.: 1"), "export should include No, but...: 1")
end)

-- ============================================================================
-- Summary
-- ============================================================================

print("\n========================================")
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("========================================\n")

if failed > 0 then
	os.exit(1)
end
