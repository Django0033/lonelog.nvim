#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

local tokenizer = require("lonelog.parsers.tokenizer")
local passed, failed = 0, 0

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

local function check_type(name, line, expected_type)
	local result = tokenizer.tokenize(line)
	if result and result.type == expected_type then
		print("PASS " .. name)
		passed = passed + 1
	else
		local got = result and result.type or "nil"
		print(string.format("FAIL %s: got %s, expected %s", name, got, expected_type))
		failed = failed + 1
	end
end

print("Testing tokenizer:")
print("====================")

check_type("action", "@ Follow the trail", "action")
check_type("action with indent", "  @ Search", "action")
check_type("question", "? Is it safe?", "question")
check_type("dice", "d: 2d6+3 -> 9", "dice")
check_type("dice no result", "d: 2d6+3", "dice")
check_type("consequence", "=> The path is clear", "consequence")
check_type("scene", "### S1 *Entering*", "scene")
check_type("scene flashback", "### S3b *Flashback*", "scene")
check_type("header session", "## Session 5", "header")
check_type("header campaign", "=== Campaign ===", "header")
check_type("narrative", "---", "narrative")
check_type("narrative backslash", "\\---", "narrative")
check_type("gen", "gen: Generate NPC", "gen")
check_type("tbl range", "tbl: Forest (d6)", "tbl")
check_type("tbl bracket", "tbl: Weather [A, B]", "tbl")
check_type("meta", "(note: test)", "meta")
check_type("combat block", "[COMBAT]", "combat_block")
check_type("combat close", "[/COMBAT]", "combat_block")
check_type("text fallback", "Just some narrative text", "text")
check("nil for empty", tokenizer.tokenize(""), nil)
check("nil for whitespace", tokenizer.tokenize("   "), nil)
check("nil for nil", tokenizer.tokenize(nil), nil)

-- Test dice tokens
do
	local t = tokenizer.tokenize("d: 2d6+3 -> 9")
	if t and t.tokens then
		check("dice tokens: prefix", t.tokens[1].type, "dice_prefix")
		check("dice tokens: notation", t.tokens[2].type, "notation")
		check("dice tokens: arrow", t.tokens[3].type, "result_arrow")
		check("dice tokens: result", t.tokens[4].type, "result_value")
	else
		print("FAIL dice tokens: no tokens")
		failed = failed + 1
	end
end

-- Test scene tokens
do
	local t = tokenizer.tokenize("### S1 *Entering the forest*")
	if t and t.tokens then
		check("scene tokens: id", t.tokens[1].type, "scene_id")
		check("scene tokens: context", t.tokens[2].type, "context")
		check("scene tokens: text", t.tokens[2].text, "Entering the forest")
	else
		print("FAIL scene tokens: no tokens")
		failed = failed + 1
	end
end

-- Test meta tokens
do
	local t = tokenizer.tokenize("(note: something important)")
	if t and t.tokens then
		check("meta tokens: content", t.tokens[2].text, "note: something important")
	else
		print("FAIL meta tokens: no tokens")
		failed = failed + 1
	end
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
	os.exit(1)
end
