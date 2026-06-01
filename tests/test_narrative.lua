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
local M = require("lonelog.commands.narrative")

local passed, failed = 0, 0

print("Testing narrative block functions:")
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

-- Test build_narrative_block
local block = M.build_narrative_block()
check("block has 3 lines", #block, 3)
check("opening delimiter", block[1], "\\---")
check("blank middle", block[2], "")
check("closing delimiter", block[3], "---\\")

-- Test insert_narrative_block exists
check("insert_narrative_block exists", type(M.insert_narrative_block), "function")

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
