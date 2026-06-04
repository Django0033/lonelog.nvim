#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- Mock vim API for headless testing
_G.vim = {
  api = {
    nvim_get_current_buf = function() return 1 end,
    nvim_buf_get_lines = function(bufnr, start, last, _strict)
      -- Will be set per test block
      return _mock_lines or {}
    end,
    nvim_buf_get_changedtick = function() return 0 end,
  },
  notify = function() end,
  log = { levels = {} },
}

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

local function check_table_deep(name, got, expected, path)
  path = path or ""
  if type(got) ~= type(expected) then
    print(string.format("FAIL %s%s: type mismatch %s vs %s", name, path, type(got), type(expected)))
    failed = failed + 1
    return
  end
  if type(got) ~= "table" then
    if got == expected then
      print("PASS " .. name .. path)
      passed = passed + 1
    else
      print(string.format("FAIL %s%s: got %s, expected %s", name, path, tostring(got), tostring(expected)))
      failed = failed + 1
    end
    return
  end
  for k, v in pairs(expected) do
    if type(k) == "number" then
      -- For arrays, check by index
      check_table_deep(name, got[k], v, path .. "[" .. k .. "]")
    else
      check_table_deep(name, got[k], v, path .. "." .. k)
    end
  end
end

-- Helper: set mock buffer lines
local function with_lines(lines)
  _mock_lines = lines
  _G.vim.api.nvim_buf_get_lines = function(_, _, _, _)
    return _mock_lines
  end
end

print("Testing combat parser (production path):")
print("========================================")

-- =============================================
-- 1. Basic block parsing: well-formed block
-- =============================================
do
  with_lines({
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
  })
  local blocks = combat.parse_combat_blocks()
  check("block: count", #blocks, 1)
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

-- =============================================
-- 2. Combatants parsed correctly (PC/foe inline)
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[PC:Alex|HP 10/10]",
    "[F:Goblin|HP 5/5]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 then
    check("combatant: PC Alex", blocks[1].combatants[1].name, "Alex")
    check("combatant: PC type", blocks[1].combatants[1].type, "PC")
    check("combatant: foe name", blocks[1].combatants[2].name, "Goblin")
    check("combatant: foe type", blocks[1].combatants[2].type, "foe")
  end
end

-- =============================================
-- 3. Round markers
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1",
    "R3",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 then
    check("rounds: R1", blocks[1].rounds[1].number, 1)
    check("rounds: R3", blocks[1].rounds[2].number, 3)
    check("rounds: current_round", blocks[1].current_round, 3)
  end
end

-- =============================================
-- 4. Unclosed combat block
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1",
    "[/COMBAT]",
    "",
    "[COMBAT]",
    "R1",
  })
  local blocks = combat.parse_combat_blocks()
  check("unclosed: blocks count", #blocks, 2)
  if #blocks >= 2 then
    check("unclosed: first is closed", blocks[1].is_closed, true)
    check("unclosed: second is open", blocks[2].is_closed, false)
    check("unclosed: second end_line nil", blocks[2].end_line == nil, true)
  end
end

-- =============================================
-- 5. No combat blocks
-- =============================================
do
  with_lines({ "plain text", "more text" })
  local blocks = combat.parse_combat_blocks()
  check("no blocks: empty", #blocks, 0)
end

-- =============================================
-- 6. Empty combat block
-- =============================================
do
  with_lines({ "[COMBAT]", "[/COMBAT]" })
  local blocks = combat.parse_combat_blocks()
  check("empty block: count", #blocks, 1)
  if #blocks >= 1 then
    check("empty block: is_closed", blocks[1].is_closed, true)
    check("empty block: no combatants", #blocks[1].combatants, 0)
    check("empty block: no rounds", #blocks[1].rounds, 0)
  end
end

-- =============================================
-- 7. Roster line adds combatants
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1 Roster: [PC:Kael|HP 8] [F:Jefe|HP 12]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 then
    check("roster: combatants count", #blocks[1].combatants, 2)
    if #blocks[1].combatants >= 2 then
      check("roster: PC from roster", blocks[1].combatants[1].name, "Kael")
      check("roster: foe from roster", blocks[1].combatants[2].name, "Jefe")
    end
  end
end

-- =============================================
-- 7b. Roster dedup: tag + roster line same combatant
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1",
    "[F:Goblin|HP 5|alerta]",
    "R2 Roster: [F:Goblin|HP 5] [PC:Kael|HP 12/12]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and blocks[1].combatants then
    check("roster dedup: total count", #blocks[1].combatants, 2)
    local goblin_count = 0
    for _, c in ipairs(blocks[1].combatants) do
      if c.name == "Goblin" then goblin_count = goblin_count + 1 end
    end
    check("roster dedup: Goblin appears once", goblin_count, 1)
  end
end

-- =============================================
-- 8. Multiple combat blocks
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1",
    "[/COMBAT]",
    "[COMBAT]",
    "R1",
    "R2",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  check("multiple: count", #blocks, 2)
  if #blocks >= 2 then
    check("multiple: block1 rounds", #blocks[1].rounds, 1)
    check("multiple: block2 rounds", #blocks[2].rounds, 2)
  end
end

-- =============================================
-- 9. Action line classification
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "@ Goblin attacks!",
    "d: 1d8+2 -> 5",
    "A narrative line",
    "[PC:Alex|HP 10/10]",
    "* GM note",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 then
    local actions = blocks[1].actions
    check("actions: count", #actions, 5)
    if #actions >= 5 then
      check("actions: @ is narrative", actions[1].type, "narrative")
      check("actions: d: is dice", actions[2].type, "dice")
      check("actions: plain is action", actions[3].type, "action")
      check("actions: tag is tag", actions[4].type, "tag")
      check("actions: * is note", actions[5].type, "note")
      check("actions: content preserved", actions[1].content, "@ Goblin attacks!")
      check("actions: line number", actions[1].line, 2)
    end
  end
end

-- =============================================
-- 10. is_dead: field says "dead"
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[F:Goblin|dead]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and #blocks[1].combatants >= 1 then
    check("is_dead: field says dead", blocks[1].combatants[1].is_dead, true)
  end
end

-- =============================================
-- 11. is_dead: zero HP
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[F:Goblin|HP 0/5]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and #blocks[1].combatants >= 1 then
    check("is_dead: zero HP", blocks[1].combatants[1].is_dead, true)
  end
end

-- =============================================
-- 12. is_dead: negative HP
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[F:Goblin|HP -3]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and #blocks[1].combatants >= 1 then
    check("is_dead: negative HP", blocks[1].combatants[1].is_dead, true)
  end
end

-- =============================================
-- 13. is_dead: positive HP
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[F:Goblin|HP 10/10]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and #blocks[1].combatants >= 1 then
    check("is_dead: positive HP", blocks[1].combatants[1].is_dead, false)
  end
end

-- =============================================
-- 14. Combatant stats: inline tag
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[PC:Alex|HP 10/10|warrior]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and #blocks[1].combatants >= 1 then
    check("stats: PC Alex field", blocks[1].combatants[1].stats[1], "HP 10/10")
  end
end

-- =============================================
-- 15. Roster excludes dead entries
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1 Roster: [PC:Kael|HP 8] [F:Goblin|dead]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 then
    check("roster: excludes dead", #blocks[1].combatants, 1)
    if #blocks[1].combatants >= 1 then
      check("roster: only alive added", blocks[1].combatants[1].name, "Kael")
    end
  end
end

-- =============================================
-- 16. Combatant dedup by name+type (update stats)
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[PC:Alex|HP 10/10]",
    "[PC:Alex|HP 5/10]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 then
    check("dedup: only one Alex", #blocks[1].combatants, 1)
    if #blocks[1].combatants >= 1 then
      check("dedup: Alex stats updated", blocks[1].combatants[1].stats[1], "HP 5/10")
    end
  end
end

-- =============================================
-- 17. Roster lines tracked per round
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "R1",
    "R1 Roster: [PC:Kael|HP 8]",
    "R2",
    "R2 Roster: [PC:Kael|HP 4]",
    "[/COMBAT]",
  })
  local blocks = combat.parse_combat_blocks()
  if #blocks >= 1 and #blocks[1].rounds >= 2 then
    check("roster_lines: round 1 count", #blocks[1].rounds[1].roster_lines, 1)
    check("roster_lines: round 2 count", #blocks[1].rounds[2].roster_lines, 1)
    if #blocks[1].rounds[1].roster_lines >= 1 then
      check("roster_lines: round 1 line", blocks[1].rounds[1].roster_lines[1], 3)
    end
  end
end

-- =============================================
-- 18. is_dead exported function
-- =============================================
do
  check("is_dead(): 'dead' returns true", combat.is_dead("dead"), true)
  check("is_dead(): 'Dead' case-insensitive", combat.is_dead("Dead"), true)
  check("is_dead(): 'HP 0/5' returns true", combat.is_dead("HP 0/5"), true)
  check("is_dead(): 'HP -3' returns true", combat.is_dead("HP -3"), true)
  check("is_dead(): 'HP 10/10' returns false", combat.is_dead("HP 10/10"), false)
  check("is_dead(): 'alive' returns false", combat.is_dead("alive"), false)
end

-- =============================================
-- 19. Default buffer (0 = current) is handled
-- =============================================
do
  with_lines({
    "[COMBAT]",
    "[/COMBAT]",
  })
  local blocks_default = combat.parse_combat_blocks()
  local blocks_explicit = combat.parse_combat_blocks(1)
  check("default bufnr: works", #blocks_default, 1)
  check("explicit bufnr: works", #blocks_explicit, 1)
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
