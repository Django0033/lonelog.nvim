#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

_G.vim = {
	split = function(s, sep)
		local result = {}
		for w in s:gmatch("[^" .. sep .. "]+") do
			table.insert(result, w)
		end
		return result
	end,
	trim = function(s)
		return s:match("^%s*(.-)%s*$") or s
	end,
}

local tables = require("lonelog.parsers.tables")

local passed = 0
local failed = 0

local function test(name, ok)
	if ok then
		print("  PASS " .. name)
	else
		print("  FAIL " .. name)
	end
	return ok
end

print("=== resolve_entry ===")

local test_def = {
	name = "Test",
	dice = "d6",
	entries = {
		{ min = 1, max = 3, text = "Low" },
		{ min = 4, max = 5, text = "Medium" },
		{ min = 6, max = 6, text = "High" },
	},
}

if test("value 1 -> Low", tables.resolve_entry(test_def, 1) == "Low") then
	passed = passed + 1
else
	failed = failed + 1
end
if test("value 4 -> Medium", tables.resolve_entry(test_def, 4) == "Medium") then
	passed = passed + 1
else
	failed = failed + 1
end
if test("value 6 -> High", tables.resolve_entry(test_def, 6) == "High") then
	passed = passed + 1
else
	failed = failed + 1
end
if test("value 0 -> nil", tables.resolve_entry(test_def, 0) == nil) then
	passed = passed + 1
else
	failed = failed + 1
end
if test("value 7 -> nil", tables.resolve_entry(test_def, 7) == nil) then
	passed = passed + 1
else
	failed = failed + 1
end
if test("empty entries -> nil",
	tables.resolve_entry({ name = "E", dice = "d6", entries = {} }, 1) == nil)
then
	passed = passed + 1
else
	failed = failed + 1
end

print()
print("=== parse_header ===")

do
	local r = tables.parse_header("tbl: Forest (d6)")
	if test("range header", r and r.name == "Forest" and r.dice == "d6" and r.options == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_header("tbl: Weather [Sunny, Rain, Storm]")
	local ok = r and r.name == "Weather" and r.dice == "d3"
		and #r.options == 3 and r.options[1] == "Sunny"
		and r.options[2] == "Rain" and r.options[3] == "Storm"
	if test("bracket header", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_header("tbl: Test (d20) [A, B]")
	if test("mixed format captured as plain name", r ~= nil and r.dice == nil and r.options == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_header("  tbl: Indented [X]")
	if test("indented header", r and r.name == "Indented") then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_header("not a table")
	if test("no match -> nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_header("tbl: JustName")
	if test("name only (no dice/bracket)", r and r.name == "JustName" and r.dice == nil and r.options == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

print()
print("=== parse_tables ===")

do
	local r = tables.parse_tables({
		"tbl: Forest (d6)",
		"  1-3: Nothing",
		"  4-5: Deer",
		"  6: Ambush",
	})
	local t = r["forest"]
	local ok = t and #t.entries == 3 and t.dice == "d6" and t.name == "Forest"
		and t.entries[1].min == 1 and t.entries[1].max == 3 and t.entries[1].text == "Nothing"
		and t.entries[2].min == 4 and t.entries[2].max == 5 and t.entries[2].text == "Deer"
		and t.entries[3].min == 6 and t.entries[3].max == 6 and t.entries[3].text == "Ambush"
	if test("range table", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({ "tbl: Weather [Sunny, Rain, Storm]" })
	local t = r["weather"]
	local ok = t and #t.entries == 3 and t.dice == "d3"
		and t.entries[1].text == "Sunny" and t.entries[1].min == 1
		and t.entries[2].text == "Rain" and t.entries[2].min == 2
		and t.entries[3].text == "Storm" and t.entries[3].min == 3
	if test("bracket shorthand", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({ "tbl: Empty (d6)" })
	local t = r["empty"]
	if test("no entries", t and #t.entries == 0) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({
		"tbl: Alpha (d4)",
		"  1: One",
		"tbl: Beta (d6)",
		"  1: Uno",
	})
	local ok = r["alpha"] and r["beta"] and #r["alpha"].entries == 1 and #r["beta"].entries == 1
	if test("multiple tables", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({
		"tbl: A (d6)",
		"  1: One",
		"Some random text",
		"tbl: B (d6)",
		"  1: Uno",
	})
	local ok = r["a"] and r["b"] and #r["a"].entries == 1 and #r["b"].entries == 1
	if test("non-table text closes table", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({
		"tbl: A (d6)",
		"  1: One",
		"",
		"  2: Two",
	})
	local ok = r["a"] and #r["a"].entries == 2
	if test("empty line in entries", ok) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({ "not a table", "also not" })
	if test("no tables -> empty", next(r) == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_tables({ "tbl: TabTest (d6)", "\t1: Tab entry" })
	local t = r["tabtest"]
	if test("tab indentation", t and #t.entries == 1 and t.entries[1].text == "Tab entry") then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

print()
print("=== parse_roll_line ===")

do
	local r = tables.parse_roll_line("tbl: Forest Encounters d6=5")
	if test("match with dice", r and r.name == "forest encounters" and r.value == 5) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_roll_line("tbl: Weather =3")
	if test("match without dice", r and r.name == "weather" and r.value == 3) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_roll_line("tbl: Forest Encounters (d6)")
	if test("no =value -> nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_roll_line("not a table line")
	if test("no match -> nil", r == nil) then
		passed = passed + 1
	else
		failed = failed + 1
	end
end

do
	local r = tables.parse_roll_line("tbl: Complex Name d20=18")
	if test("d20 notation", r and r.name == "complex name" and r.value == 18) then
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
