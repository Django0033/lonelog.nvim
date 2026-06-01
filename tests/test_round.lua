#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.commands.round")

local passed, failed = 0, 0

print("Testing round marker functions:")
print("==============================")

local function check(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    passed = passed + 1
  else
    print(string.format("FAIL %s: got %s, expected %s", name, tostring(got), tostring(expected)))
    failed = failed + 1
  end
end

local function deep_equal(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i].type ~= b[i].type or a[i].name ~= b[i].name or a[i].field ~= b[i].field then
      return false
    end
  end
  return true
end

-- ============================================================
-- find_combat_block
-- ============================================================

do
  local lines = {
    "[COMBAT]",
    "",
    "R1",
    "@ Attack",
    "[/COMBAT]",
  }

  do
    local s, e = M.find_combat_block(lines, 3)
    check("combat block: cursor inside returns bounds", s == 1 and e == 5, true)
  end

  do
    local s, e = M.find_combat_block(lines, 1)
    check("combat block: cursor on [COMBAT]", s == 1 and e == 5, true)
  end

  do
    local s, e = M.find_combat_block(lines, 5)
    check("combat block: cursor on [/COMBAT]", s == 1 and e == 5, true)
  end

  do
    local s, e = M.find_combat_block(lines, 6)
    check("combat block: cursor outside returns nil", s == nil and e == nil, true)
  end
end

do
  local lines = {
    "Some text",
    "R1",
    "[COMBAT]",
    "R2",
    "[/COMBAT]",
  }

  local s, e = M.find_combat_block(lines, 4)
  check("combat block: ignores R outside block", s == 3 and e == 5, true)
end

do
  local lines = { "No combat block here" }
  local s, e = M.find_combat_block(lines, 1)
  check("combat block: no block at all", s == nil and e == nil, true)
end

do
  local lines = {
    "[COMBAT]",
    "R1",
    "[/COMBAT]",
    "[COMBAT]",
    "R2",
    "[/COMBAT]",
  }

  do
    local s, e = M.find_combat_block(lines, 5)
    check("combat block: multiple blocks, inside second", s == 4 and e == 6, true)
  end

  do
    local s, e = M.find_combat_block(lines, 2)
    check("combat block: multiple blocks, inside first", s == 1 and e == 3, true)
  end
end

-- ============================================================
-- find_highest_round
-- ============================================================

do
  local lines = { "R1", "some text", "R3", "R7" }
  local n = M.find_highest_round(lines, 1, 4)
  check("highest round: multiple rounds R1,R3,R7 → 7", n, 7)
end

do
  local lines = { "R1", "R2", "R3" }
  local n = M.find_highest_round(lines, 1, 3)
  check("highest round: consecutive R1,R2,R3 → 3", n, 3)
end

do
  local lines = { "no rounds here", "just text" }
  local n = M.find_highest_round(lines, 1, 2)
  check("highest round: no rounds → 0", n, 0)
end

do
  local lines = { "R4 Roster: [PC:Kael|HP 12]", "R5", "R2" }
  local n = M.find_highest_round(lines, 1, 3)
  check("highest round: roster line R4 → 5", n, 5)
end

do
  local lines = { "Text", "R1", "More", "R2", "Last" }
  local n = M.find_highest_round(lines, 3, 5)
  check("highest round: range subset ignores R1", n, 2)
end

-- ============================================================
-- collect_roster
-- ============================================================

do
  local lines = {
    "R1",
    "@ Attack",
    "d: hit -> [F:Jefe|HP 12|armadura]",
    "d: miss -> [F:Matón|HP 3]",
    "",
  }
  local roster = M.collect_roster(lines, 1, 5)
  check("roster: two foes with HP", #roster, 2)

  if #roster >= 2 then
    check("roster: first foe name", roster[1].name, "Jefe")
    check("roster: first foe type", roster[1].type, "F")
    check("roster: first foe field", roster[1].field, "HP 12")
    check("roster: second foe name", roster[2].name, "Matón")
    check("roster: second foe field", roster[2].field, "HP 3")
  end
end

do
  local lines = {
    "R1",
    "@ Heal -> [PC:Kael|HP 8]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("roster: PC with HP", #roster, 1)
  if #roster >= 1 then
    check("roster: PC name", roster[1].name, "Kael")
    check("roster: PC type", roster[1].type, "PC")
    check("roster: PC field", roster[1].field, "HP 8")
  end
end

do
  local lines = {
    "R1",
    "@ Heal -> [PC:Kael|HP 8]",
    "d: hit -> [F:Jefe|HP 12]",
  }
  local roster = M.collect_roster(lines, 1, 3)
  check("roster: mixed PC and Foe", #roster, 2)
end

do
  local lines = {
    "R1",
    "@ open door",
    "d: investigate -> success",
  }
  local roster = M.collect_roster(lines, 1, 3)
  check("roster: no relevant tags", #roster, 0)
end

do
  local lines = {
    "R1",
    "[PC:django|guapo]",
    "[F:arana|fea]",
  }
  local roster = M.collect_roster(lines, 1, 3)
  check("roster: descriptive fields without HP", #roster, 2)
  if #roster >= 2 then
    check("roster: PC descriptive field", roster[1].field, "guapo")
    check("roster: F descriptive field", roster[2].field, "fea")
  end
end

do
  local lines = {
    "R1",
    "d: -> [N:Guardia|alerta] [F:Jefe|HP 10]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("roster: ignores NPC tag", #roster, 1)
  if #roster >= 1 then
    check("roster: only F tag collected", roster[1].type, "F")
  end
end

-- ============================================================
-- is_dead (death detection in collect_roster)
-- ============================================================

do
  local lines = {
    "R1",
    "[F:arana|dead]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: descriptive 'dead' excluded", #roster, 0)
end

do
  local lines = {
    "R1",
    "[F:Jefe|Dead]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: case-insensitive 'Dead' excluded", #roster, 0)
end

do
  local lines = {
    "R1",
    "[PC:Kael|HP 0]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: HP 0 excluded", #roster, 0)
end

do
  local lines = {
    "R1",
    "[F:Goblin|HP -2]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: HP negative excluded", #roster, 0)
end

do
  local lines = {
    "R1",
    "[PC:django|guapo]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: descriptive alive included", #roster, 1)
  if #roster >= 1 then
    check("dead: alive name preserved", roster[1].name, "django")
  end
end

do
  local lines = {
    "R1",
    "[F:Jefe|HP 12]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: HP positive included", #roster, 1)
end

do
  local lines = {
    "R1",
    "[PC:Kael|HP 8]",
    "[F:Jefe|HP 12]",
    "[F:arana|dead]",
    "[F:Goblin|HP 0]",
  }
  local roster = M.collect_roster(lines, 1, 4)
  check("dead: mixed — only alive in roster", #roster, 2)
  if #roster >= 2 then
    check("dead: first survivor is PC", roster[1].type, "PC")
    check("dead: second survivor is F", roster[2].type, "F")
  end
end

do
  local lines = {
    "R1",
    "[F:spider|deadly poison]",
  }
  local roster = M.collect_roster(lines, 1, 2)
  check("dead: 'deadly poison' excluded (starts with dead)", #roster, 0)
end

-- ============================================================
-- build_roster_line
-- ============================================================

do
  local roster = {
    { type = "PC", name = "Kael", field = "HP 8" },
    { type = "F", name = "Jefe", field = "HP 12" },
  }
  local line = M.build_roster_line(2, roster)
  local expected = "R2 Roster: [PC:Kael|HP 8] [F:Jefe|HP 12]"
  check("roster line: formats correctly", line, expected)
end

do
  local line = M.build_roster_line(5, {})
  check("roster line: empty roster", line, "R5 Roster: ")
end

do
  local roster = {
    { type = "PC", name = "django", field = "guapo" },
    { type = "F", name = "arana", field = "fea" },
  }
  local line = M.build_roster_line(2, roster)
  local expected = "R2 Roster: [PC:django|guapo] [F:arana|fea]"
  check("roster line: descriptive fields without HP", line, expected)
end

-- ============================================================
-- insert_round exists
-- ============================================================

check("insert_round exists", type(M.insert_round), "function")

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
