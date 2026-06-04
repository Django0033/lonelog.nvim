#!/usr/bin/env lua

vim = {
  fn = { line = function() return 1 end },
  api = {
    nvim_buf_set_lines = function() end,
    nvim_win_set_cursor = function() end,
  },
  cmd = function() end,
}

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.addons.combat.combat")

local passed, failed = 0, 0

print("Testing combat block functions:")
print("============================")

local function check(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    passed = passed + 1
  else
    print(string.format("FAIL %s: got %s, expected %s", name, tostring(got), tostring(expected)))
    failed = failed + 1
  end
end

-- Test build_combat_block
local block = M.build_combat_block()
check("block has 3 lines", #block, 3)
check("opening delimiter", block[1], "[COMBAT]")
check("blank middle", block[2], "")
check("closing delimiter", block[3], "[/COMBAT]")

-- Test insert_combat_block exists
check("insert_combat_block exists", type(M.insert_combat_block), "function")

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
