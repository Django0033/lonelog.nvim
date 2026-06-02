#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

local combat = require("lonelog.parsers.combat")
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

print("Testing combat parser:")
print("========================")

-- Test: Basic block parsing
do
  local lines = {
    "Before text",
    "",
    "[COMBAT]",
    "R1",
    "@ Goblin attacks!",
    "d: 1d8+2 -> 5",
    "[PC:Alex|HP 10/10]",
    "[F:Goblin|HP 5/5]",
    "",
    "R2",
    "@ Alex strikes",
    "d: 1d6+3 -> 7",
    "[F:Goblin|HP 0/5|dead]",
    "[/COMBAT]",
    "",
    "After text",
  }
  local blocks = combat.parse_combat_blocks(lines)
  check("blocks: count", #blocks, 1)
  if #blocks >= 1 then
    local b = blocks[1]
    check("block: start_line", b.start_line, 3)
    check("block: end_line", b.end_line, 14)
    check("block: is_closed", b.is_closed, true)
    check("block: current_round", b.current_round, 2)
    check("block: combatants count", #b.combatants, 2)
    check("block: rounds count", #b.rounds, 2)
  end
end

-- Test: Combatants parsed correctly
do
  local lines = {
    "[COMBAT]",
    "[PC:Alex|HP 10/10]",
    "[F:Goblin|HP 5/5]",
    "[/COMBAT]",
  }
  local blocks = combat.parse_combat_blocks(lines)
  if #blocks >= 1 then
    check("combatant: PC Alex", blocks[1].combatants[1].name, "Alex")
    check("combatant: PC type", blocks[1].combatants[1].type, "PC")
    check("combatant: foe Goblin", blocks[1].combatants[2].name, "Goblin")
    check("combatant: foe type", blocks[1].combatants[2].type, "foe")
  end
end

-- Test: Round markers
do
  local lines = {
    "[COMBAT]",
    "R1",
    "R3",
    "[/COMBAT]",
  }
  local blocks = combat.parse_combat_blocks(lines)
  if #blocks >= 1 then
    check("rounds: R1", blocks[1].rounds[1].number, 1)
    check("rounds: R3", blocks[1].rounds[2].number, 3)
    check("rounds: current_round", blocks[1].current_round, 3)
  end
end

-- Test: Unclosed combat block
do
  local lines = {
    "[COMBAT]",
    "R1",
    "[/COMBAT]",
    "",
    "[COMBAT]",
    "R1",
  }
  local blocks = combat.parse_combat_blocks(lines)
  check("unclosed: blocks count", #blocks, 2)
  if #blocks >= 2 then
    check("unclosed: first is closed", blocks[1].is_closed, true)
    check("unclosed: second is open", blocks[2].is_closed, false)
  end
end

-- Test: No combat blocks
do
  local lines = { "plain text", "more text" }
  local blocks = combat.parse_combat_blocks(lines)
  check("no blocks: empty", #blocks, 0)
end

-- Test: Empty combat block
do
  local lines = { "[COMBAT]", "[/COMBAT]" }
  local blocks = combat.parse_combat_blocks(lines)
  check("empty block: count", #blocks, 1)
  if #blocks >= 1 then
    check("empty block: is_closed", blocks[1].is_closed, true)
    check("empty block: no combatants", #blocks[1].combatants, 0)
    check("empty block: no rounds", #blocks[1].rounds, 0)
  end
end

-- Test: Roster line adds combatants
do
  local lines = {
    "[COMBAT]",
    "R1 Roster: [PC:Kael|HP 8] [F:Jefe|HP 12]",
    "[/COMBAT]",
  }
  local blocks = combat.parse_combat_blocks(lines)
  if #blocks >= 1 then
    check("roster: combatants count", #blocks[1].combatants, 2)
    if #blocks[1].combatants >= 2 then
      check("roster: PC from roster", blocks[1].combatants[1].name, "Kael")
      check("roster: foe from roster", blocks[1].combatants[2].name, "Jefe")
    end
  end
end

-- Test: Multiple combat blocks
do
  local lines = {
    "[COMBAT]",
    "R1",
    "[/COMBAT]",
    "[COMBAT]",
    "R1",
    "R2",
    "[/COMBAT]",
  }
  local blocks = combat.parse_combat_blocks(lines)
  check("multiple: count", #blocks, 2)
  if #blocks >= 2 then
    check("multiple: block1 rounds", #blocks[1].rounds, 1)
    check("multiple: block2 rounds", #blocks[2].rounds, 2)
  end
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
