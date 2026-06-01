#!/usr/bin/env lua

-- Mock Neovim APIs used by addon registration
local commands = {}
local keymaps = {}

vim = {
  api = {
    nvim_create_user_command = function(name, command, opts)
      table.insert(commands, { name = name, command = command, opts = opts })
    end,
  },
  keymap = {
    set = function(mode, lhs, rhs, opts)
      table.insert(keymaps, { mode = mode, lhs = lhs, rhs = rhs, opts = opts })
    end,
  },
  deepcopy = function(t) return t end,
  tbl_deep_extend = function(_, a, b) return b or a end,
  notify = function() end,
  log = { levels = { WARN = "WARN", ERROR = "ERROR" } },
}

local commands = {}
local keymaps = {}

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local passed, failed = 0, 0

local function check(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    passed = passed + 1
  else
    print(string.format("FAIL %s: got %s, expected %s", name, tostring(got), tostring(expected)))
    failed = failed + 1
  end
end

local function find_cmd(name)
  for _, c in ipairs(commands) do
    if c.name == name then return c end
  end
end

local function find_km(lhs)
  for _, k in ipairs(keymaps) do
    if k.lhs == lhs then return k end
  end
end

-- ============================================================
-- Combat addon registration
-- ============================================================

do
  local combat = require("lonelog.addons.combat")
  check("combat: name", combat.name, "combat")
  check("combat: has commands", #combat.commands > 0, true)
  check("combat: has keymaps", #combat.keymaps > 0, true)
  check("combat: keymap uses config key not LHS", combat.keymaps[1].key ~= nil, true)
  check("combat: keymap has mode", combat.keymaps[1].mode, "n")

  local found_combat, found_round = false, false
  for _, cmd in ipairs(combat.commands) do
    if cmd.name == "LonelogCombat" then found_combat = true end
    if cmd.name == "LonelogRound" then found_round = true end
  end
  check("combat: has LonelogCombat command", found_combat, true)
  check("combat: has LonelogRound command", found_round, true)
end

-- ============================================================
-- Dungeon addon registration
-- ============================================================

do
  local dungeon = require("lonelog.addons.dungeon")
  check("dungeon: name", dungeon.name, "dungeon")
  check("dungeon: has commands", #dungeon.commands > 0, true)
  check("dungeon: has keymaps", #dungeon.keymaps > 0, true)
  check("dungeon: keymap uses config key not LHS", dungeon.keymaps[1].key ~= nil, true)

  local found_status, found_go, found_state = false, false, false
  for _, cmd in ipairs(dungeon.commands) do
    if cmd.name == "LonelogDungeonStatus" then found_status = true end
    if cmd.name == "LonelogRoomGo" then found_go = true end
    if cmd.name == "LonelogRoomState" then found_state = true end
  end
  check("dungeon: has LonelogDungeonStatus command", found_status, true)
  check("dungeon: has LonelogRoomGo command", found_go, true)
  check("dungeon: has LonelogRoomState command", found_state, true)
end

-- ============================================================
-- Core commands dir has no addon files
-- ============================================================

do
  local ok, _ = pcall(require, "lonelog.commands.combat")
  check("core: combat removed from commands/", ok, false)
  local ok2, _ = pcall(require, "lonelog.commands.dungeon_status")
  check("core: dungeon_status removed from commands/", ok2, false)
end

-- ============================================================
-- Config has addon defaults
-- ============================================================

do
  -- Use defaults (no setup call)
  local defs = require("lonelog.config").get()
  check("config: combat addon default enabled", defs.addons.combat, true)
  check("config: dungeon addon default enabled", defs.addons.dungeon, true)
end

-- ============================================================

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
