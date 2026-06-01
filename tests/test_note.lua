#!/usr/bin/env lua

vim = {
  fn = {
    line = function() return 1 end,
    col = function() return 0 end,
  },
  api = {
    nvim_get_current_line = function() return "" end,
    nvim_set_current_line = function() end,
    nvim_win_set_cursor = function() end,
  },
}

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.commands.note")

local passed, failed = 0, 0

print("Testing meta note functions:")
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

-- Test build_note
local note = M.build_note()
check("build_note returns (note: )", note, "(note: )")

-- Test insert_note exists
check("insert_note exists", type(M.insert_note), "function")

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
