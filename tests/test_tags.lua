#!/usr/bin/env lua
-- Test script for tags parser

vim = {
  deepcopy = function(t)
    local function deepcopy(obj)
      if type(obj) == 'table' then
        local copy = {}
        for k, v in pairs(obj) do
          copy[deepcopy(k)] = deepcopy(v)
        end
        return copy
      else
        return obj
      end
    end
    return deepcopy(t)
  end,
  api = {
    nvim_buf_get_lines = function() return {} end,
    nvim_buf_get_name = function() return "test.md" end,
    nvim_get_current_buf = function() return 1 end,
  },
  tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
  tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
}

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.ui.parsers").tags

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
  -- Multi-line tags (raw format with newlines)
  { input = "[N:Name\n  | content1\n  | content2\n]", expected_type = "N", expected_name = "Name",
    expected_tags = {"content1", "content2"}, expected_multiline = true },
  { input = "[L:Cave\n  | dark\n  | damp\n]", expected_type = "L", expected_name = "Cave",
    expected_tags = {"dark", "damp"}, expected_multiline = true },
  { input = "[N:Solo\n  | alone\n]", expected_type = "N", expected_name = "Solo",
    expected_tags = {"alone"}, expected_multiline = true },
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
    if tc.expected_ref == false and result.is_reference then
      table.insert(errors, "expected non-reference tag")
      ok = false
    end
    if tc.expected_multiline ~= nil and result.is_multiline ~= tc.expected_multiline then
      table.insert(errors, string.format("is_multiline: got %s, expected %s", tostring(result.is_multiline), tostring(tc.expected_multiline)))
      ok = false
    end
    if tc.expected_tags then
      local got = table.concat(result.tags, ",")
      local exp = table.concat(tc.expected_tags, ",")
      if got ~= exp then
        table.insert(errors, string.format("tags: got {%s}, expected {%s}", got, exp))
        ok = false
      end
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
print()
print("Testing _normalize_multiline function:")
print("=======================================")

-- Test _normalize_multiline directly
local ml_tests = {
  {
    input = "[N:Name\n  | content1\n  | content2\n]",
    expected = "[N:Name|content1|content2]",
  },
  {
    input = "[L:Cave\n  | dark\n  | damp\n]",
    expected = "[L:Cave|dark|damp]",
  },
  {
    input = "[N:Solo\n  | alone\n]",
    expected = "[N:Solo|alone]",
  },
  -- Single-line should pass through unchanged
  {
    input = "[N:Jonah|friendly]",
    expected = "[N:Jonah|friendly]",
  },
  -- Empty content lines (no pipe content)
  {
    input = "[N:Empty\n|\n]",
    expected = "[N:Empty]",
  },
}

for _, tc in ipairs(ml_tests) do
  local result = M._normalize_multiline(tc.input)
  if result == tc.expected then
    print(string.format("PASS normalize: %q", tc.input:gsub("\n", "\\n")))
    passed = passed + 1
  else
    print(string.format("FAIL normalize: %q\n  got:      %q\n  expected: %q", tc.input:gsub("\n", "\\n"), result, tc.expected))
    failed = failed + 1
  end
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
