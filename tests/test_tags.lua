#!/usr/bin/env lua
-- Test script for tags parser

vim = {
  api = { nvim_buf_get_lines = function() return {} end },
  tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
  tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
}

package.path = package.path .. ";./lua/?.lua"
local parsers = require("lonelog.ui.parsers")
local M = parsers

-- Run tests
local test_cases = {
  { input = "[N:Jonah|friendly|wounded]", expected_type = "N", expected_name = "Jonah" },
  { input = "[N:Jonah]", expected_type = "N", expected_name = "Jonah" },
  { input = "[L:Library|dark|quiet]", expected_type = "L", expected_name = "Library" },
  { input = "[E:Alert 2/6]", expected_type = "E", expected_name = "Alert" },
  { input = "[PC:Alex|HP 8]", expected_type = "PC", expected_name = "Alex" },
  { input = "[Thread:Main Quest|Open]", expected_type = "THREAD", expected_name = "Main Quest" },
  { input = "[#N:Jonah]", expected_type = "N", expected_name = "Jonah", expected_ref = true },
  { input = "[N:Jonah| friendly → hostile]", expected_type = "N", expected_name = "Jonah" },
  { input = "[N:Jonah|+captured]", expected_type = "N", expected_name = "Jonah" },
  { input = "[N:Jonah|-wounded]", expected_type = "N", expected_name = "Jonah" },
  { input = "[Inv:Slot 1-2 | sniper rifle (d12)]", expected_type = "INV", expected_name = "Slot 1-2" },
  { input = "[R:1 | active | reception]", expected_type = "R", expected_name = "1" },
  { input = "[F: flesh blob | dead]", expected_type = "F", expected_name = "flesh blob" },
  { input = "[PC: Michael (Mirror) | hp 5/5]", expected_type = "PC", expected_name = "Michael (Mirror)" },
}

print("Testing parse_tag function:")
print("==============================")

local passed = 0
local failed = 0

for _, tc in ipairs(test_cases) do
  local result = M.parse_tag(tc.input, 1)
  
  if result then
    local ok = true
    local errors = {}
    
    if result.type ~= tc.expected_type then
      table.insert(errors, string.format("type: got %s, expected %s", result.type, tc.expected_type))
      ok = false
    end
    if result.name ~= tc.expected_name then
      table.insert(errors, string.format("name: got %s, expected %s", result.name, tc.expected_name))
      ok = false
    end
    if tc.expected_ref and not result.is_reference then
      table.insert(errors, "expected reference tag")
      ok = false
    end
    
    if ok then
      print(string.format("PASS [%s] %s", tc.expected_type, tc.input))
      passed = passed + 1
    else
      print(string.format("FAIL [%s] %s", tc.expected_type, tc.input))
      for _, err in ipairs(errors) do
        print("  - " .. err)
      end
      failed = failed + 1
    end
  else
    print(string.format("FAIL [%s] %s - returned nil", tc.expected_type, tc.input))
    failed = failed + 1
  end
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
