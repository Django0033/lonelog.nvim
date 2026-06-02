#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

local _G_vim = _G.vim
_G.vim = _G_vim or {
  api = {},
  fn = {},
  cmd = function() end,
  notify = function() end,
  log = { levels = {} },
}

local prose = require("lonelog.parsers.prose")
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

local function check_table(name, got, expected)
  local ok = true
  if type(got) ~= "table" or type(expected) ~= "table" then
    ok = got == expected
  elseif #got ~= #expected then
    ok = false
  else
    for i, v in ipairs(expected) do
      if type(v) == "table" then
        if type(got[i]) ~= "table" then ok = false; break end
        for k, val in pairs(v) do
          if got[i][k] ~= val then ok = false; break end
        end
      elseif got[i] ~= v then
        ok = false; break
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

print("Testing prose parser:")
print("======================")

-- Test: meta note
do
  local result = prose.parse_prose({ "(note: something important)" })
  check_table("meta note", result.meta_notes, {
    { content = "note: something important", line = 1 },
  })
end

-- Test: dialogue simple
do
  local result = prose.parse_prose({ 'Alex: "Hello there"' })
  check_table("dialogue simple", result.dialogues, {
    { speaker = "Alex", text = "Hello there", line = 1 },
  })
end

-- Test: dialogue PC
do
  local result = prose.parse_prose({ 'PC (Kael): "I investigate the room"' })
  check_table("dialogue PC", result.dialogues, {
    { speaker = "PC (Kael)", text = "I investigate the room", line = 1 },
  })
end

-- Test: dialogue NPC prefix
do
  local result = prose.parse_prose({ 'N: "Watch out!"' })
  check_table("dialogue NPC", result.dialogues, {
    { speaker = "N", text = "Watch out!", line = 1 },
  })
end

-- Test: narrative block
do
  local lines = {
    "some text",
    "\\---",
    "The wind howled through the trees.",
    "Darkness surrounded them.",
    "---\\",
    "more text",
  }
  local result = prose.parse_prose(lines)
  check_table("narrative block", result.narrative_blocks, {
    { start_line = 2, end_line = 5 },
  })
end

-- Test: standalone --- narrative (start and end same marker)
do
  local lines = {
    "before",
    "---",
    "A dark forest looms ahead.",
    "The path is barely visible.",
    "---",
    "after",
  }
  local result = prose.parse_prose(lines)
  check_table("narrative standalone", result.narrative_blocks, {
    { start_line = 2, end_line = 5 },
  })
end

-- Test: mixed content
do
  local lines = {
    "(note: test note)",
    'Alex: "Hello"',
    "Plain text line",
    'N: "Greetings"',
  }
  local result = prose.parse_prose(lines)
  check("mixed: meta count", #result.meta_notes, 1)
  check("mixed: dialogue count", #result.dialogues, 2)
  check("mixed: narrative count", #result.narrative_blocks, 0)
end

-- Test: empty/whitespace lines
do
  local result = prose.parse_prose({ "", "   " })
  check("empty lines: no metas", #result.meta_notes, 0)
  check("empty lines: no dialogues", #result.dialogues, 0)
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
